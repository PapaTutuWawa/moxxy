import 'dart:async';
import 'dart:collection';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart' as dio;
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:mime/mime.dart';
import 'package:moxplatform/moxplatform.dart';
import 'package:moxxyv2/service/connectivity.dart';
import 'package:moxxyv2/service/conversation.dart';
import 'package:moxxyv2/service/database.dart';
import 'package:moxxyv2/service/httpfiletransfer/helpers.dart';
import 'package:moxxyv2/service/httpfiletransfer/jobs.dart';
import 'package:moxxyv2/service/message.dart';
import 'package:moxxyv2/service/notifications.dart';
import 'package:moxxyv2/service/service.dart';
import 'package:moxxyv2/shared/error_types.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/xmpp/connection.dart';
import 'package:moxxyv2/xmpp/managers/namespaces.dart';
import 'package:moxxyv2/xmpp/message.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0363.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0446.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0447.dart';
import 'package:path/path.dart' as pathlib;
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

  /// Actually attempt to upload the file described by the job [job].
  Future<void> _performFileUpload(FileUploadJob job) async {
    _log.finest('Beginning upload of ${job.path}');
    final file = File(job.path);
    final data = await file.readAsBytes();
    final stat = file.statSync();

    // Request the upload slot
    final conn = GetIt.I.get<XmppConnection>();
    final httpManager = conn.getManagerById<HttpFileUploadManager>(httpFileUploadManager)!;
    final slotResult = await httpManager.requestUploadSlot(
      pathlib.basename(job.path),
      stat.size,
    );

    if (slotResult.isError()) {
      _log.severe('Failed to request upload slot for ${job.path}!');
      await _nextUploadJob();
      return;
    }

    final slot = slotResult.getValue();
    final fileMime = lookupMimeType(job.path);
    
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
          final progress = count.toDouble() / total.toDouble();
          sendEvent(
            ProgressEvent(
              id: job.message.id,
              progress: progress == 1 ? 0.99 : progress,
            ),
          );
        },
      );

      final ms = GetIt.I.get<MessageService>();
      if (response.statusCode != 201) {
        // TODO(PapaTutuWawa): Trigger event
        _log.severe('Upload failed');

        // Notify UI of upload failure
        final msg = await ms.updateMessage(
          job.message.id,
          errorType: fileUploadFailedError,
        );
        sendEvent(
          MessageUpdatedEvent(
            message: msg.copyWith(isUploading: false),
          ),
        );
      } else {
        _log.fine('Upload was successful');

        // Notify UI of upload completion
        var msg = job.message;

        // Reset a stored error, if there was one
        if (msg.errorType != null) {
          msg = await ms.updateMessage(
            msg.id,
            errorType: noError,
          );
        }
        sendEvent(
          MessageUpdatedEvent(
            message: msg.copyWith(isUploading: false),
          ),
        );

        // Send the message to the recipient
        conn.getManagerById<MessageManager>(messageManager)!.sendMessage(
          MessageDetails(
            to: job.recipient,
            body: slot.getUrl,
            requestDeliveryReceipt: true,
            id: job.message.sid,
            originId: job.message.originId,
            sfs: StatelessFileSharingData(
              url: slot.getUrl,
              metadata: FileMetadataData(
                mediaType: fileMime,
                size: stat.size,
                name: pathlib.basename(job.path),
                // TODO(Unknown): Add a thumbnail
                thumbnails: [],
              ),
            ),
          ),
        );
        _log.finest('Sent message with file upload for ${job.path}');
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
    _log.finest('Downloading ${job.url}');
    final uri = Uri.parse(job.url);
    final filename = uri.pathSegments.last;
    final downloadedPath = await getDownloadPath(filename, job.conversationJid, job.mimeGuess);

    try {
      final response = await dio.Dio().downloadUri(
        uri,
        downloadedPath,
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

      if (!isRequestOkay(response.statusCode)) {
        // TODO(PapaTutuWawa): Error handling
        // TODO(PapaTutuWawa): Trigger event
        _log.warning('HTTP GET of ${job.url} returned ${response.statusCode}');
      } else {
        // Check the MIME type
        final notification = GetIt.I.get<NotificationsService>();
        final mime = job.mimeGuess ?? lookupMimeType(downloadedPath);

        if (mime != null && ['image/', 'video/', 'audio/'].any(mime.startsWith)) {
          MoxplatformPlugin.media.scanFile(downloadedPath);
        }

        final msg = await GetIt.I.get<MessageService>().updateMessage(
          job.mId,
          mediaUrl: downloadedPath,
          mediaType: mime,
        );

        sendEvent(MessageUpdatedEvent(message: msg.copyWith(isDownloading: false)));

        if (notification.shouldShowNotification(msg.conversationJid)) {
          _log.finest('Creating notification with bigPicture $downloadedPath');
          await notification.showNotification(msg, '');
        }

        final conv = (await GetIt.I.get<ConversationService>().getConversationByJid(job.conversationJid))!;
        final sharedMedium = await GetIt.I.get<DatabaseService>().addSharedMediumFromData(
          downloadedPath,
          msg.timestamp,
          mime: mime,
        );
        final newConv = await GetIt.I.get<ConversationService>().updateConversation(
          conv.id,
          sharedMedia: [sharedMedium],
        );
        sendEvent(ConversationUpdatedEvent(conversation: newConv));
      }
    } on dio.DioError catch(err) {
      // TODO(PapaTutuWawa): React if we received an error that is not related to the
      //                     connection.
      _log.finest('Error: $err');
    }

    // Free the download resources for the next one
    if (GetIt.I.get<ConnectivityService>().currentState == ConnectivityResult.none) return;
    await _uploadLock.synchronized(() async {
      if (_uploadQueue.isNotEmpty) {
        _currentDownloadJob = _downloadQueue.removeFirst();
        unawaited(_performFileDownload(_currentDownloadJob!));
      } else {
        _currentDownloadJob = null;
      }
    });
  }
}
