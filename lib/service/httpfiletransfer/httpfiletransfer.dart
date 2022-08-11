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
import 'package:moxxyv2/shared/events.dart';
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
    final data = await File(job.path).readAsBytes();
    final putUri = Uri.parse(job.putUrl);

    try {
      final response = await dio.Dio().putUri<dynamic>(
        putUri,
        options: dio.Options(
          headers: job.headers,
          contentType: 'application/octet-stream',
          requestEncoder: (_, __) => data,
        ),
        data: data,
        onSendProgress: (count, total) {
          final progress = count.toDouble() / total.toDouble();
          sendEvent(
            ProgressEvent(
              id: job.mId,
              progress: progress == 1 ? 0.99 : progress,
            ),
          );
        },
      );

      if (response.statusCode != 201) {
        // TODO(PapaTutuWawa): Trigger event
        _log.severe('Upload failed');
      } else {
        // TODO(PapaTutuWawa): Trigger event
        _log.fine('Upload was successful');
      }
    } on dio.DioError {
      // TODO(PapaTutuWawa): Check if this is a timeout
      _log.finest('Upload failed due to connection error');
      return;
    }

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
      // TODO(PapaTutuWawa): Do something
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
