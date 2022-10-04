import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart' as dio;
import 'package:get_it/get_it.dart';
import 'package:image_size_getter/file_input.dart';
import 'package:image_size_getter/image_size_getter.dart';
import 'package:logging/logging.dart';
import 'package:mime/mime.dart';
import 'package:moxplatform/moxplatform.dart';
import 'package:moxxyv2/service/connectivity.dart';
import 'package:moxxyv2/service/conversation.dart';
import 'package:moxxyv2/service/cryptography/cryptography.dart';
import 'package:moxxyv2/service/cryptography/types.dart';
import 'package:moxxyv2/service/database/database.dart';
import 'package:moxxyv2/service/httpfiletransfer/helpers.dart';
import 'package:moxxyv2/service/httpfiletransfer/jobs.dart';
import 'package:moxxyv2/service/message.dart';
import 'package:moxxyv2/service/notifications.dart';
import 'package:moxxyv2/service/service.dart';
import 'package:moxxyv2/shared/error_types.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/shared/models/media.dart';
import 'package:moxxyv2/shared/warning_types.dart';
import 'package:moxxyv2/xmpp/connection.dart';
import 'package:moxxyv2/xmpp/managers/namespaces.dart';
import 'package:moxxyv2/xmpp/message.dart';
import 'package:moxxyv2/xmpp/namespaces.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0300.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0363.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0446.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0447.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0448.dart';
import 'package:path/path.dart' as pathlib;
import 'package:path_provider/path_provider.dart';
import 'package:random_string/random_string.dart';
import 'package:synchronized/synchronized.dart';

/// This service is responsible for managing the up- and download of files using Http.
class HttpFileTransferService {
  HttpFileTransferService()
    : _uploadQueue = Queue<FileUploadJob>(),
      _downloadQueue = Queue<FileDownloadJob>(),
      _uploadLock = Lock(),
      _downloadLock = Lock(),
      _log = Logger('HttpFileTransferService');

  final Logger _log;

  /// Queues for tracking up- and download tasks
  final Queue<FileDownloadJob> _downloadQueue;
  final Queue<FileUploadJob> _uploadQueue;
  /// The currently running job and their lock
  FileUploadJob? _currentUploadJob;
  FileDownloadJob? _currentDownloadJob;

  /// Locks for upload and download state
  final Lock _uploadLock;
  final Lock _downloadLock;
  
  /// Called by the ConnectivityService if the connection got lost but then was regained.
  Future<void> onConnectivityChanged(bool regained) async {
    if (!regained) return;
    
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
    var canDownload = false;
    await _uploadLock.synchronized(() async {
      if (_currentDownloadJob != null) {
        _downloadQueue.add(job);
      } else {
        _currentDownloadJob = job;
        canDownload = true;
      }
    });

    if (canDownload) {
      unawaited(_performFileDownload(job));
    }
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

      encryption = await GetIt.I.get<CryptographyService>().encryptFile(
        job.path,
        path,
        SFSEncryptionType.aes256GcmNoPadding,
      );
    }

    final file = File(path);
    final data = await file.readAsBytes();
    final stat = file.statSync();
    
    // Request the upload slot
    final conn = GetIt.I.get<XmppConnection>();
    final httpManager = conn.getManagerById<HttpFileUploadManager>(httpFileUploadManager)!;
    final slotResult = await httpManager.requestUploadSlot(
      pathlib.basename(path),
      stat.size,
    );

    if (slotResult.isError()) {
      _log.severe('Failed to request upload slot for ${job.path}!');
      await _nextUploadJob();
      return;
    }

    final slot = slotResult.getValue();
    try {
      final response = await dio.Dio().putUri<dynamic>(
        Uri.parse(slot.putUrl),
        options: dio.Options(
          headers: slot.headers,
          contentType: 'application/octet-stream',
          requestEncoder: (_, __) => data,
        ),
        data: data,
        onSendProgress: (count, total) {
          // TODO(PapaTutuWawa): Make this smarter by also checking if one of those chats
          //                     is open.
          if (job.recipients.length == 1) {
            final progress = count.toDouble() / total.toDouble();
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
      if (response.statusCode != 201) {
        // TODO(PapaTutuWawa): Trigger event
        _log.severe('Upload failed');

        // Notify UI of upload failure
        for (final recipient in job.recipients) {
          final msg = await ms.updateMessage(
            job.messageMap[recipient]!.id,
            errorType: fileUploadFailedError,
            isUploading: false,
          );
          sendEvent(MessageUpdatedEvent(message: msg));
        }
      } else {
        _log.fine('Upload was successful');

        for (final recipient in job.recipients) {
          // Notify UI of upload completion
          var msg = job.messageMap[recipient]!;

          // Reset a stored error, if there was one
          msg = await ms.updateMessage(
            msg.id,
            errorType: noError,
            encryptionScheme: encryption != null ?
              SFSEncryptionType.aes256GcmNoPadding.toNamespace() :
              null,
            key: encryption != null ? base64Encode(encryption.key) : null,
            iv: encryption != null ? base64Encode(encryption.iv) : null,
            isUploading: false,
            srcUrl: slot.getUrl,
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
            plaintextHashes[hashSha256] = await GetIt.I.get<CryptographyService>().hashFile(job.path, HashFunction.sha256);
          }
          
          // Send the message to the recipient
          conn.getManagerById<MessageManager>(messageManager)!.sendMessage(
            MessageDetails(
              to: recipient,
              body: slot.getUrl,
              requestDeliveryReceipt: true,
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
              funReplacement: msg.sid,
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
    } on dio.DioError {
      // TODO(PapaTutuWawa): Check if this is a timeout
      _log.finest('Upload failed due to connection error');
      return;
    }

    await _nextUploadJob();
  }

  Future<void> _nextUploadJob() async {
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
  
  /// Actually attempt to download the file described by the job [job].
  Future<void> _performFileDownload(FileDownloadJob job) async {
    final filename = job.location.filename;
    _log.finest('Downloading ${job.location.url} as $filename');
    final downloadedPath = await getDownloadPath(filename, job.conversationJid, job.mimeGuess);

    var downloadPath = downloadedPath;
    if (job.location.key != null && job.location.iv != null) {
      // The file was encrypted
      final tempDir = await getTemporaryDirectory();
      downloadPath = pathlib.join(tempDir.path, filename);
    }
    
    dio.Response<dynamic>? response;
    try {
      response = await dio.Dio().downloadUri(
        Uri.parse(job.location.url),
        downloadPath,
        onReceiveProgress: (count, total) {
          final progress = count.toDouble() / total.toDouble();
          sendEvent(
            ProgressEvent(
              id: job.mId,
              progress: progress == 1 ? 0.99 : progress,
            ),
          );
        },
      );
    } on dio.DioError catch(err) {
      // TODO(PapaTutuWawa): React if we received an error that is not related to the
      //                     connection.
      _log.finest('Error: $err');
    }

    if (!isRequestOkay(response?.statusCode)) {
      // TODO(PapaTutuWawa): Error handling
      // TODO(PapaTutuWawa): Trigger event
      _log.warning('HTTP GET of ${job.location.url} returned ${response?.statusCode}');
    } else {
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
          final msg = await GetIt.I.get<MessageService>().updateMessage(
            job.mId,
            isFileUploadNotification: false,
            errorType: messageFailedToDecryptFile,
            isDownloading: false,
          );
          sendEvent(MessageUpdatedEvent(message: msg));

          // We cannot do anything more so just bail
          await _pickNextDownloadTask();
          return;
        }

        integrityCheckPassed = result.plaintextOkay && result.ciphertextOkay;
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
          // TODO(Unknown): Restrict to the library's supported file types
          Size? size;
          try {
            size = ImageSizeGetter.getSize(FileInput(File(downloadedPath)));
          } catch (ex) {
            _log.warning('Failed to get image size for $downloadedPath: $ex');
          }

          mediaWidth = size?.width;
          mediaHeight = size?.height;
        } else if (mime.startsWith('video/')) {
          // TODO(Unknown): Also figure out the thumbnail size here
          MoxplatformPlugin.media.scanFile(downloadedPath);
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
        isFileUploadNotification: false,
        warningType: integrityCheckPassed ?
          warningFileIntegrityCheckFailed :
          null,
        errorType: conv.encrypted && !decryptionKeysAvailable ?
          messageChatEncryptedButFileNot :
          null,
        isDownloading: false,
      );

      sendEvent(MessageUpdatedEvent(message: msg));

      if (notification.shouldShowNotification(msg.conversationJid) && job.shouldShowNotification) {
        _log.finest('Creating notification with bigPicture $downloadedPath');
        await notification.showNotification(msg, '');
      }

      final sharedMedium = await GetIt.I.get<DatabaseService>().addSharedMediumFromData(
        downloadedPath,
        msg.timestamp,
        conv.id,
        mime: mime,
      );
      final newConv = conv.copyWith(
        sharedMedia: List<SharedMedium>.from(conv.sharedMedia)..add(sharedMedium),
      );
      sendEvent(ConversationUpdatedEvent(conversation: newConv));
    }

    // Free the download resources for the next one
    await _pickNextDownloadTask();
  }

  Future<void> _pickNextDownloadTask() async {
    if (GetIt.I.get<ConnectivityService>().currentState == ConnectivityResult.none) return;

    await _downloadLock.synchronized(() async {
      if (_downloadQueue.isNotEmpty) {
        _currentDownloadJob = _downloadQueue.removeFirst();
        unawaited(_performFileDownload(_currentDownloadJob!));
      } else {
        _currentDownloadJob = null;
      }
    });
  }
}
