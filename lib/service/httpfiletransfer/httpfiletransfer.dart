import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:mime/mime.dart';
import 'package:moxplatform/moxplatform.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxyv2/service/connectivity.dart';
import 'package:moxxyv2/service/conversation.dart';
import 'package:moxxyv2/service/cryptography/cryptography.dart';
import 'package:moxxyv2/service/cryptography/types.dart';
import 'package:moxxyv2/service/files.dart';
import 'package:moxxyv2/service/httpfiletransfer/client.dart' as client;
import 'package:moxxyv2/service/httpfiletransfer/helpers.dart';
import 'package:moxxyv2/service/httpfiletransfer/jobs.dart';
import 'package:moxxyv2/service/httpfiletransfer/location.dart';
import 'package:moxxyv2/service/message.dart';
import 'package:moxxyv2/service/notifications.dart';
import 'package:moxxyv2/service/service.dart';
import 'package:moxxyv2/shared/error_types.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/shared/warning_types.dart';
import 'package:path/path.dart' as pathlib;
import 'package:path_provider/path_provider.dart';
import 'package:random_string/random_string.dart';
import 'package:synchronized/synchronized.dart';
import 'package:uuid/uuid.dart';

/// This service is responsible for managing the up- and download of files using Http.
class HttpFileTransferService {
  HttpFileTransferService() {
    GetIt.I.get<ConnectivityService>().stream.listen(_onConnectivityChanged);
  }

  final Logger _log = Logger('HttpFileTransferService');

  /// Queues for tracking up- and download tasks
  final Queue<FileDownloadJob> _downloadQueue = Queue<FileDownloadJob>();
  final Queue<FileUploadJob> _uploadQueue = Queue<FileUploadJob>();

  /// The currently running job and their lock
  FileUploadJob? _currentUploadJob;
  FileDownloadJob? _currentDownloadJob;

  /// Locks for upload and download state
  final Lock _uploadLock = Lock();
  final Lock _downloadLock = Lock();

  /// Called by the ConnectivityService if the connection got lost but then was regained.
  Future<void> _onConnectivityChanged(ConnectivityEvent event) async {
    if (!event.regained) return;

    await _uploadLock.synchronized(() async {
      if (_currentUploadJob != null) {
        _log.finest(
          'Connectivity regained and there is still an upload job. Restarting it.',
        );
        unawaited(_performFileUpload(_currentUploadJob!));
      } else {
        if (_uploadQueue.isNotEmpty) {
          _log.finest(
            'Connectivity regained and the upload queue is not empty. Starting a new upload job.',
          );
          _currentUploadJob = _uploadQueue.removeFirst();
          unawaited(_performFileUpload(_currentUploadJob!));
        }
      }
    });

    await _downloadLock.synchronized(() async {
      if (_currentDownloadJob != null) {
        _log.finest(
          'Connectivity regained and there is still a download job. Restarting it.',
        );
        unawaited(_performFileDownload(_currentDownloadJob!));
      } else {
        if (_downloadQueue.isNotEmpty) {
          _log.finest(
            'Connectivity regained and the download queue is not empty. Starting a new download job.',
          );
          _currentDownloadJob = _downloadQueue.removeFirst();
          unawaited(_performFileDownload(_currentDownloadJob!));
        }
      }
    });
  }

  /// Queue the upload job [job] to be performed.
  Future<void> uploadFile(FileUploadJob job) async {
    var canUpload = false;
    await _uploadLock.synchronized(() async {
      if (_currentUploadJob != null) {
        _uploadQueue.add(job);
      } else {
        _currentUploadJob = job;
        canUpload = true;
      }
    });

    if (canUpload) {
      unawaited(_performFileUpload(job));
    }
  }

  /// Queue the download job [job] to be performed.
  Future<void> downloadFile(FileDownloadJob job) async {
    await _uploadLock.synchronized(() async {
      if (_currentDownloadJob != null) {
        _log.finest('Queuing up download task.');
        _downloadQueue.add(job);
      } else {
        _log.finest('Executing download task.');
        _currentDownloadJob = job;

        unawaited(_performFileDownload(job));
      }
    });
  }

  Future<void> _copyFile(
    FileUploadJob job,
    String to,
  ) async {
    if (!File(to).existsSync()) {
      await File(job.path).copy(to);

      // Let the media scanner index the file
      MoxplatformPlugin.media.scanFile(to);
    } else {
      _log.finest(
        'Skipping file copy on upload as file is already at media location',
      );
    }
  }

  Future<void> _fileUploadFailed(
    FileUploadJob job,
    MessageErrorType error,
  ) async {
    final ms = GetIt.I.get<MessageService>();
    final cs = GetIt.I.get<ConversationService>();

    // Notify UI of upload failure
    for (final recipient in job.recipients) {
      final msg = await ms.updateMessage(
        job.messageMap[recipient]!.id,
        errorType: error,
        isUploading: false,
      );
      sendEvent(MessageUpdatedEvent(message: msg));

      // Update the conversation list
      final conversation = await cs.getConversationByJid(recipient);
      if (conversation?.lastMessage?.id == msg.id) {
        final newConversation = conversation!.copyWith(
          lastMessage: msg,
        );

        // Update the cache
        cs.setConversation(newConversation);

        sendEvent(ConversationUpdatedEvent(conversation: newConversation));
      }
    }

    await _pickNextUploadTask();
  }

  /// Actually attempt to upload the file described by the job [job].
  Future<void> _performFileUpload(FileUploadJob job) async {
    _log.finest('Beginning upload of ${job.path}');

    var path = job.path;
    final useEncryption = job.encryptMap.entries.every((entry) => entry.value);
    EncryptionResult? encryption;
    if (useEncryption) {
      final tempDir = await getTemporaryDirectory();
      final randomFilename = randomAlphaNumeric(
        20,
        provider: CoreRandomProvider.from(Random.secure()),
      );
      path = pathlib.join(tempDir.path, randomFilename);

      try {
        encryption = await GetIt.I.get<CryptographyService>().encryptFile(
              job.path,
              path,
              SFSEncryptionType.aes256GcmNoPadding,
            );
      } catch (ex) {
        _log.warning('Encrypting ${job.path} failed: $ex');
        await _fileUploadFailed(job, MessageErrorType.failedToEncryptFile);
        return;
      }
    }

    final file = File(path);
    final stat = file.statSync();

    // Request the upload slot
    final conn = GetIt.I.get<XmppConnection>();
    final httpManager =
        conn.getManagerById<HttpFileUploadManager>(httpFileUploadManager)!;
    final slotResult = await httpManager.requestUploadSlot(
      pathlib.basename(path),
      stat.size,
    );

    if (slotResult.isType<HttpFileUploadError>()) {
      _log.severe('Failed to request upload slot for ${job.path}!');
      await _fileUploadFailed(job, MessageErrorType.fileUploadFailed);
      return;
    }
    final slot = slotResult.get<HttpFileUploadSlot>();

    final uploadStatusCode = await client.uploadFile(
      Uri.parse(slot.putUrl),
      slot.headers,
      path,
      (total, current) {
        // TODO(PapaTutuWawa): Make this smarter by also checking if one of those chats
        //                     is open.
        if (job.recipients.length == 1) {
          final progress = current.toDouble() / total.toDouble();
          sendEvent(
            ProgressEvent(
              id: job.messageMap.values.first.id,
              progress: progress == 1 ? 0.99 : progress,
            ),
          );
        }
      },
    );

    final ms = GetIt.I.get<MessageService>();
    if (!isRequestOkay(uploadStatusCode)) {
      _log.severe('Upload failed due to status code $uploadStatusCode');
      await _fileUploadFailed(job, MessageErrorType.fileUploadFailed);
      return;
    } else {
      _log.fine('Upload was successful');

      // Get hashes
      StatelessFileSharingSource source;
      final plaintextHashes = <HashFunction, String>{};
      Map<HashFunction, String>? ciphertextHashes;
      if (encryption != null) {
        source = StatelessFileSharingEncryptedSource(
          SFSEncryptionType.aes256GcmNoPadding,
          encryption.key,
          encryption.iv,
          encryption.ciphertextHashes,
          StatelessFileSharingUrlSource(slot.getUrl),
        );

        plaintextHashes.addAll(encryption.plaintextHashes);
        ciphertextHashes = encryption.ciphertextHashes;
      } else {
        source = StatelessFileSharingUrlSource(slot.getUrl);
        try {
          plaintextHashes[HashFunction.sha256] = await GetIt.I
              .get<CryptographyService>()
              .hashFile(job.path, HashFunction.sha256);
        } catch (ex) {
          _log.warning('Failed to hash file ${job.path} using SHA-256: $ex');
        }
      }

      // Update the metadata
      final filename = pathlib.basename(job.path);
      final filePath = await computeCachedPathForFile(
        filename,
        plaintextHashes,
      );
      final metadataWrapper =
          await GetIt.I.get<FilesService>().createFileMetadataIfRequired(
                MediaFileLocation(
                  [slot.getUrl],
                  filename,
                  encryption != null
                      ? SFSEncryptionType.aes256GcmNoPadding.toNamespace()
                      : null,
                  encryption?.key,
                  encryption?.iv,
                  plaintextHashes,
                  ciphertextHashes,
                  stat.size,
                ),
                job.mime,
                stat.size,
                null,
                // TODO(Unknown): job.thumbnails.first
                null,
                null,
                path: filePath,
              );
      var metadata = metadataWrapper.fileMetadata;

      // Remove the tempoary metadata if we already know the file
      if (metadataWrapper.retrieved) {
        // Only skip the copy if the existing file metadata has a path associated with it
        if (metadataWrapper.fileMetadata.path != null) {
          _log.fine(
            'Uploaded file $filename is already tracked. Skipping copy.',
          );
        } else {
          _log.fine(
            'Uploaded file $filename is already tracked but has no path. Copying...',
          );
          await _copyFile(job, filePath);
          metadata = await GetIt.I.get<FilesService>().updateFileMetadata(
                metadata.id,
                path: filePath,
              );
        }
      } else {
        _log.fine('Uploaded file $filename not tracked. Copying...');
        await _copyFile(job, metadataWrapper.fileMetadata.path!);
      }

      const uuid = Uuid();
      for (final recipient in job.recipients) {
        // Notify UI of upload completion
        var msg = await ms.updateMessage(
          job.messageMap[recipient]!.id,
          errorType: null,
          isUploading: false,
          fileMetadata: metadata,
        );
        // TODO(Unknown): Maybe batch those two together?
        final oldSid = msg.sid;
        msg = await ms.updateMessage(
          msg.id,
          sid: uuid.v4(),
          originId: uuid.v4(),
        );
        sendEvent(MessageUpdatedEvent(message: msg));

        // Send the message to the recipient
        await conn.getManagerById<MessageManager>(messageManager)!.sendMessage(
              JID.fromString(recipient),
              TypedMap<StanzaHandlerExtension>.fromList([
                MessageBodyData(slot.getUrl),
                const MessageDeliveryReceiptData(true),
                StableIdData(msg.originId, null),
                StatelessFileSharingData(
                  FileMetadataData(
                    mediaType: job.mime,
                    size: stat.size,
                    name: filename,
                    thumbnails: job.thumbnails,
                    hashes: plaintextHashes,
                  ),
                  [source],
                  includeOOBFallback: true,
                ),
                FileUploadNotificationReplacementData(oldSid),
                MessageIdData(msg.sid),
              ]),
            );
        _log.finest(
          'Sent message with file upload for ${job.path} to $recipient',
        );
      }

      // Remove the old metadata only here because we would otherwise violate a foreign key
      // constraint.
      if (metadataWrapper.retrieved) {
        await GetIt.I.get<FilesService>().removeFileMetadata(
              job.metadataId,
            );
      }
    }

    await _pickNextUploadTask();
  }

  Future<void> _pickNextUploadTask() async {
    // Free the upload resources for the next one
    if (GetIt.I.get<ConnectivityService>().currentState ==
        ConnectivityResult.none) return;
    await _uploadLock.synchronized(() async {
      if (_uploadQueue.isNotEmpty) {
        _currentUploadJob = _uploadQueue.removeFirst();
        unawaited(_performFileUpload(_currentUploadJob!));
      } else {
        _currentUploadJob = null;
      }
    });
  }

  Future<void> _fileDownloadFailed(
    FileDownloadJob job,
    MessageErrorType error,
  ) async {
    final ms = GetIt.I.get<MessageService>();

    // Notify UI of download failure
    final msg = await ms.updateMessage(
      job.mId,
      errorType: error,
      isDownloading: false,
    );
    sendEvent(MessageUpdatedEvent(message: msg));

    await _pickNextDownloadTask();
  }

  /// Actually attempt to download the file described by the job [job].
  Future<void> _performFileDownload(FileDownloadJob job) async {
    final filename = job.location.filename;
    final downloadedPath = await computeCachedPathForFile(
      job.location.filename,
      job.location.plaintextHashes,
    );

    var downloadPath = downloadedPath;
    if (job.location.key != null && job.location.iv != null) {
      // The file was encrypted
      final tempDir = await getTemporaryDirectory();
      downloadPath = pathlib.join(tempDir.path, filename);
    }

    // TODO(Unknown): Maybe try other URLs?
    final downloadUrl = job.location.urls.first;
    _log.finest(
      'Downloading $downloadUrl as $filename (MIME guess ${job.mimeGuess}) to $downloadPath (-> $downloadedPath)',
    );

    int? downloadStatusCode;
    var integrityCheckPassed = true;
    try {
      _log.finest('Beginning download...');
      downloadStatusCode = await client.downloadFile(
        Uri.parse(downloadUrl),
        downloadPath,
        (total, current) {
          final progress = current.toDouble() / total.toDouble();
          sendEvent(
            ProgressEvent(
              id: job.mId,
              progress: progress == 1 ? 0.99 : progress,
            ),
          );
        },
      );
      _log.finest('Download done...');
    } catch (err) {
      _log.finest('Failed to download: $err');
    }

    if (!isRequestOkay(downloadStatusCode)) {
      _log.warning(
        'HTTP GET of $downloadUrl returned $downloadStatusCode',
      );
      await _fileDownloadFailed(job, MessageErrorType.fileDownloadFailed);
      return;
    }

    final decryptionKeysAvailable =
        job.location.key != null && job.location.iv != null;
    final crypto = GetIt.I.get<CryptographyService>();
    if (decryptionKeysAvailable) {
      // The file was downloaded and is now being decrypted
      sendEvent(
        ProgressEvent(
          id: job.mId,
        ),
      );

      try {
        final result = await crypto.decryptFile(
          downloadPath,
          downloadedPath,
          SFSEncryptionType.fromNamespace(job.location.encryptionScheme!),
          job.location.key!,
          job.location.iv!,
          job.location.plaintextHashes ?? {},
          job.location.ciphertextHashes ?? {},
        );

        if (!result.decryptionOkay) {
          _log.warning('Failed to decrypt $downloadPath');
          await _fileDownloadFailed(job, MessageErrorType.failedToDecryptFile);
          return;
        }

        integrityCheckPassed = result.plaintextOkay && result.ciphertextOkay;
      } catch (ex) {
        _log.warning(
          'Decryption of $downloadPath ($downloadedPath) failed: $ex',
        );
        await _fileDownloadFailed(job, MessageErrorType.failedToDecryptFile);
        return;
      }

      unawaited(
        Directory(pathlib.dirname(downloadPath)).delete(recursive: true),
      );
    } else if (job.location.plaintextHashes?.isNotEmpty ?? false) {
      // Verify only the plaintext hash
      // TODO(Unknown): Allow verification of other hash functions
      if (job.location.plaintextHashes![HashFunction.sha256] != null) {
        final hash = await crypto.hashFile(
          downloadPath,
          HashFunction.sha256,
        );
        integrityCheckPassed =
            hash == job.location.plaintextHashes![HashFunction.sha256];
      } else if (job.location.plaintextHashes![HashFunction.sha512] != null) {
        final hash = await crypto.hashFile(
          downloadPath,
          HashFunction.sha512,
        );
        integrityCheckPassed =
            hash == job.location.plaintextHashes![HashFunction.sha512];
      } else {
        _log.warning(
          'Could not verify file integrity as no accelerated hash function is available (${job.location.plaintextHashes!.keys})',
        );
      }
    }

    // Check the MIME type
    final notification = GetIt.I.get<NotificationsService>();
    final mime = job.mimeGuess ?? lookupMimeType(downloadedPath);

    int? mediaWidth;
    int? mediaHeight;
    if (mime != null) {
      if (mime.startsWith('image/')) {
        MoxplatformPlugin.media.scanFile(downloadedPath);

        // Find out the dimensions
        final imageSize = await getImageSizeFromPath(downloadedPath);
        if (imageSize == null) {
          _log.warning('Failed to get image size for $downloadedPath');
        }

        mediaWidth = imageSize?.width.toInt();
        mediaHeight = imageSize?.height.toInt();
      } else if (mime.startsWith('video/')) {
        MoxplatformPlugin.media.scanFile(downloadedPath);

        /*
        // Generate thumbnail
        final thumbnailPath = await getVideoThumbnailPath(
          downloadedPath,
          job.conversationJid,
        );

        // Find out the dimensions
        final imageSize = await getImageSizeFromPath(thumbnailPath);
        if (imageSize == null) {
          _log.warning('Failed to get image size for $downloadedPath ($thumbnailPath)');
        }
        
        mediaWidth = imageSize?.width.toInt();
        mediaHeight = imageSize?.height.toInt();*/
      } else if (mime.startsWith('audio/')) {
        MoxplatformPlugin.media.scanFile(downloadedPath);
      }
    }

    final fs = GetIt.I.get<FilesService>();
    final metadata = await fs.updateFileMetadata(
      job.metadataId,
      path: downloadedPath,
      size: File(downloadedPath).lengthSync(),
      width: mediaWidth,
      height: mediaHeight,
      mimeType: mime,
    );

    // Only add the hash pointers if the file hashes match what was sent
    if ((job.location.plaintextHashes?.isNotEmpty ?? false) &&
        integrityCheckPassed &&
        job.createMetadataHashes) {
      await fs.createMetadataHashEntries(
        job.location.plaintextHashes!,
        job.metadataId,
      );
    }

    final cs = GetIt.I.get<ConversationService>();
    final conversation = (await cs.getConversationByJid(job.conversationJid))!;
    final msg = await GetIt.I.get<MessageService>().updateMessage(
          job.mId,
          fileMetadata: metadata,
          isFileUploadNotification: false,
          warningType:
              integrityCheckPassed ? null : warningFileIntegrityCheckFailed,
          errorType: conversation.encrypted && !decryptionKeysAvailable
              ? MessageErrorType.chatEncryptedButPlaintextFile
              : null,
          isDownloading: false,
        );

    sendEvent(MessageUpdatedEvent(message: msg));

    final updatedConversation = conversation.copyWith(
      lastMessage: conversation.lastMessage?.id == job.mId
          ? msg
          : conversation.lastMessage,
    );
    cs.setConversation(updatedConversation);

    // Show a notification
    if (notification.shouldShowNotification(msg.conversationJid) &&
        job.shouldShowNotification) {
      _log.finest('Creating notification with bigPicture $downloadedPath');
      await notification.showNotification(updatedConversation, msg, '');
    }

    sendEvent(ConversationUpdatedEvent(conversation: updatedConversation));

    // Free the download resources for the next one
    await _pickNextDownloadTask();
  }

  Future<void> _pickNextDownloadTask() async {
    await _downloadLock.synchronized(() async {
      if (_downloadQueue.isNotEmpty) {
        _currentDownloadJob = _downloadQueue.removeFirst();

        // Only download if we have a connection
        if (GetIt.I.get<ConnectivityService>().currentState !=
            ConnectivityResult.none) {
          unawaited(_performFileDownload(_currentDownloadJob!));
        }
      } else {
        _currentDownloadJob = null;
      }
    });
  }
}
