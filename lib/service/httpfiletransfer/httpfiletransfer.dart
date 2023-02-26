import 'dart:async';
import 'dart:collection';
import 'dart:convert';
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
import 'package:moxxyv2/service/database/database.dart';
import 'package:moxxyv2/service/httpfiletransfer/client.dart' as client;
import 'package:moxxyv2/service/httpfiletransfer/helpers.dart';
import 'package:moxxyv2/service/httpfiletransfer/jobs.dart';
import 'package:moxxyv2/service/message.dart';
import 'package:moxxyv2/service/notifications.dart';
import 'package:moxxyv2/service/service.dart';
import 'package:moxxyv2/shared/error_types.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/shared/models/media.dart';
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
        _log.finest('Connectivity regained and there is still an upload job. Restarting it.');
        unawaited(_performFileUpload(_currentUploadJob!));
      } else {
        if (_uploadQueue.isNotEmpty) {
          _log.finest('Connectivity regained and the upload queue is not empty. Starting a new upload job.');
          _currentUploadJob = _uploadQueue.removeFirst();
          unawaited(_performFileUpload(_currentUploadJob!));
        }
      }
    });

    await _downloadLock.synchronized(() async {
      if (_currentDownloadJob != null) {
        _log.finest('Connectivity regained and there is still a download job. Restarting it.');
        unawaited(_performFileDownload(_currentDownloadJob!));
      } else {
        if (_downloadQueue.isNotEmpty) {
          _log.finest('Connectivity regained and the download queue is not empty. Starting a new download job.');
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

  Future<void> _copyFile(FileUploadJob job) async {
    for (final recipient in job.recipients) {
      final newPath = await getDownloadPath(
        pathlib.basename(job.path),
        recipient,
        job.mime,
      );

      await File(job.path).copy(newPath);

      // Let the media scanner index the file
      MoxplatformPlugin.media.scanFile(newPath);

      // Update the message
      await GetIt.I.get<MessageService>().updateMessage(
        job.messageMap[recipient]!.id,
        mediaUrl: newPath,
      );
    }
  }

  Future<void> _fileUploadFailed(FileUploadJob job, int error) async {
    final ms = GetIt.I.get<MessageService>();

    // Notify UI of upload failure
    for (final recipient in job.recipients) {
      final msg = await ms.updateMessage(
        job.messageMap[recipient]!.id,
        errorType: error,
        isUploading: false,
      );
      sendEvent(MessageUpdatedEvent(message: msg));
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
        await _fileUploadFailed(job, messageFailedToEncryptFile);
        return;
      }
    }

    final file = File(path);
    final stat = file.statSync();

    // Request the upload slot
    final conn = GetIt.I.get<XmppConnection>();
    final httpManager = conn.getManagerById<HttpFileUploadManager>(httpFileUploadManager)!;
    final slotResult = await httpManager.requestUploadSlot(
      pathlib.basename(path),
      stat.size,
    );

    if (slotResult.isType<HttpFileUploadError>()) {
      _log.severe('Failed to request upload slot for ${job.path}!');
      await _fileUploadFailed(job, fileUploadFailedError);
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
      _log.severe('Upload failed');
      await _fileUploadFailed(job, fileUploadFailedError);
      return;
    } else {
      _log.fine('Upload was successful');

      const uuid = Uuid();
      for (final recipient in job.recipients) {
        // Notify UI of upload completion
        var msg = await ms.updateMessage(
          job.messageMap[recipient]!.id,
          mediaSize: stat.size,
          errorType: noError,
          encryptionScheme: encryption != null ?
            SFSEncryptionType.aes256GcmNoPadding.toNamespace() :
            null,
          key: encryption != null ? base64Encode(encryption.key) : null,
          iv: encryption != null ? base64Encode(encryption.iv) : null,
          isUploading: false,
          srcUrl: slot.getUrl,
        );
        // TODO(Unknown): Maybe batch those two together?
        final oldSid = msg.sid;
        msg = await ms.updateMessage(
          msg.id,
          sid: uuid.v4(),
          originId: uuid.v4(),
        );
        sendEvent(MessageUpdatedEvent(message: msg));

        StatelessFileSharingSource source;
        final plaintextHashes = <String, String>{};
        if (encryption != null) {
          source = StatelessFileSharingEncryptedSource(
            SFSEncryptionType.aes256GcmNoPadding,
            encryption.key,
            encryption.iv,
            encryption.ciphertextHashes,
            StatelessFileSharingUrlSource(slot.getUrl),
          );

          plaintextHashes.addAll(encryption.plaintextHashes);
        } else {
          source = StatelessFileSharingUrlSource(slot.getUrl);
          try {
            plaintextHashes[hashSha256] = await GetIt.I.get<CryptographyService>()
              .hashFile(job.path, HashFunction.sha256);
          } catch (ex) {
            _log.warning('Failed to hash file ${job.path} using SHA-256: $ex');
          }
        }

        // Send the message to the recipient
        conn.getManagerById<MessageManager>(messageManager)!.sendMessage(
          MessageDetails(
            to: recipient,
            body: slot.getUrl,
            requestDeliveryReceipt: true,
            id: msg.sid,
            originId: msg.originId,
            sfs: StatelessFileSharingData(
              FileMetadataData(
                mediaType: job.mime,
                size: stat.size,
                name: pathlib.basename(job.path),
                thumbnails: job.thumbnails,
                hashes: plaintextHashes,
              ),
              <StatelessFileSharingSource>[source],
            ),
            shouldEncrypt: job.encryptMap[recipient]!,
            funReplacement: oldSid,
          ),
        );
        _log.finest('Sent message with file upload for ${job.path} to $recipient');

        final isMultiMedia = job.mime?.startsWith('image/') == true || job.mime?.startsWith('video/') == true;
        if (isMultiMedia) {
          _log.finest('File appears to be either an image or a video. Copying it to the correct directory...');
          unawaited(_copyFile(job));
        }
      }
    }

    await _pickNextUploadTask();
  }

  Future<void> _pickNextUploadTask() async {
    // Free the upload resources for the next one
    if (GetIt.I.get<ConnectivityService>().currentState == ConnectivityResult.none) return;
    await _uploadLock.synchronized(() async {
      if (_uploadQueue.isNotEmpty) {
        _currentUploadJob = _uploadQueue.removeFirst();
        unawaited(_performFileUpload(_currentUploadJob!));
      } else {
        _currentUploadJob = null;
      }
    });
  }

  Future<void> _fileDownloadFailed(FileDownloadJob job, int error) async {
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
    final downloadedPath = await getDownloadPath(filename, job.conversationJid, job.mimeGuess);

    var downloadPath = downloadedPath;
    if (job.location.key != null && job.location.iv != null) {
      // The file was encrypted
      final tempDir = await getTemporaryDirectory();
      downloadPath = pathlib.join(tempDir.path, filename);
    }

    _log.finest('Downloading ${job.location.url} as $filename (MIME guess ${job.mimeGuess}) to $downloadPath (-> $downloadedPath)');

    int? downloadStatusCode;
    try {
      _log.finest('Beginning download...');
      downloadStatusCode = await client.downloadFile(
        Uri.parse(job.location.url),
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
      _log.warning('HTTP GET of ${job.location.url} returned $downloadStatusCode');
      await _fileDownloadFailed(job, fileDownloadFailedError);
      return;
    }

    var integrityCheckPassed = true;
    final conv = (await GetIt.I.get<ConversationService>()
        .getConversationByJid(job.conversationJid))!;
    final decryptionKeysAvailable = job.location.key != null && job.location.iv != null;
    if (decryptionKeysAvailable) {
      // The file was downloaded and is now being decrypted
      sendEvent(
        ProgressEvent(
          id: job.mId,
        ),
      );

      try {
        final result = await GetIt.I.get<CryptographyService>().decryptFile(
          downloadPath,
          downloadedPath,
          encryptionTypeFromNamespace(job.location.encryptionScheme!),
          job.location.key!,
          job.location.iv!,
          job.location.plaintextHashes ?? {},
          job.location.ciphertextHashes ?? {},
        );

        if (!result.decryptionOkay) {
          _log.warning('Failed to decrypt $downloadPath');
          await _fileDownloadFailed(job, messageFailedToDecryptFile);
          return;
        }

        integrityCheckPassed = result.plaintextOkay && result.ciphertextOkay;
      } catch (ex) {
        _log.warning('Decryption of $downloadPath ($downloadedPath) failed: $ex');
        await _fileDownloadFailed(job, messageFailedToDecryptFile);
        return;
      }

      unawaited(Directory(pathlib.dirname(downloadPath)).delete(recursive: true));
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

    final msg = await GetIt.I.get<MessageService>().updateMessage(
      job.mId,
      mediaUrl: downloadedPath,
      mediaType: mime,
      mediaWidth: mediaWidth,
      mediaHeight: mediaHeight,
      mediaSize: File(downloadedPath).lengthSync(),
      isFileUploadNotification: false,
      warningType: integrityCheckPassed ?
        null :
        warningFileIntegrityCheckFailed,
      errorType: conv.encrypted && !decryptionKeysAvailable ?
        messageChatEncryptedButFileNot :
        null,
      isDownloading: false,
    );

    sendEvent(MessageUpdatedEvent(message: msg));

    final sharedMedium = await GetIt.I.get<DatabaseService>().addSharedMediumFromData(
      downloadedPath,
      msg.timestamp,
      conv.jid,
      job.mId,
      mime: mime,
    );

    final cs = GetIt.I.get<ConversationService>();
    final updatedConv = await cs.createOrUpdateConversation(
      conv.jid,
      update: (c) {
        return cs.updateConversation(
          c.jid,
          sharedMediaAmount: c.sharedMediaAmount + 1,
        );
      },
    );
    final newConv = updatedConv!.copyWith(
      lastMessage: conv.lastMessage?.id == job.mId ?
        msg :
        conv.lastMessage,
      sharedMedia: clampedListPrepend<SharedMedium>(
        conv.sharedMedia,
        sharedMedium,
        8,
      ),
    );

    _log.finest('Amount of media before: ${conv.sharedMedia.length}, after: ${newConv.sharedMedia.length}');
    GetIt.I.get<ConversationService>().setConversation(newConv);

    // Show a notification
    if (notification.shouldShowNotification(msg.conversationJid) && job.shouldShowNotification) {
      _log.finest('Creating notification with bigPicture $downloadedPath');
      await notification.showNotification(newConv, msg, '');
    }
    
    sendEvent(ConversationUpdatedEvent(conversation: newConv));

    // Free the download resources for the next one
    await _pickNextDownloadTask();
  }

  Future<void> _pickNextDownloadTask() async {
    await _downloadLock.synchronized(() async {
      if (_downloadQueue.isNotEmpty) {
        _currentDownloadJob = _downloadQueue.removeFirst();

        // Only download if we have a connection
        if (GetIt.I.get<ConnectivityService>().currentState != ConnectivityResult.none) {
          unawaited(_performFileDownload(_currentDownloadJob!));
        }
      } else {
        _currentDownloadJob = null;
      }
    });
  }
}
