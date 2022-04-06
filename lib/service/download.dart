import "dart:async";
import "dart:io";

import "package:moxxyv2/shared/events.dart";
import "package:moxxyv2/service/service.dart";
import "package:moxxyv2/service/database.dart";
import "package:moxxyv2/service/notifications.dart";

import "package:logging/logging.dart";
import "package:dio/dio.dart";
import "package:path/path.dart" as path;
import "package:get_it/get_it.dart";
import "package:mime/mime.dart";
import "package:media_scanner/media_scanner.dart";
import "package:external_path/external_path.dart";

class FileMetadata {
  final String? mime;
  final int? size;

  const FileMetadata({ this.mime, this.size });
}

// TODO: Make this more reliable:
//       - Retry if a download failed, e.g. because we lost internet connection
//       - hold a queue of files to download
class DownloadService {
  final Logger _log;
  // Map the URL to download to the message id of the message we need to update
  // NOTE: This will be useful when we implement a queue 
  final Map<String, int> _tasks;
  final Map<String, int> _rateLimits; // URL -> When to send the next update

  DownloadService() : _tasks = {}, _rateLimits = {}, _log = Logger("DownloadService");

  /// Calculates the path for a given file to be saved to and, if neccessary, create it.
  Future<String> _getDownloadPath(String filename, String conversationJid, String? mime) async {
    String type;
    bool prependMoxxy = true;
    if (mime != null && ["image/", "video/"].any((e) => mime.startsWith(e))) {
      type = ExternalPath.DIRECTORY_PICTURES;
    } else {
      type = ExternalPath.DIRECTORY_DOWNLOADS;
      prependMoxxy = false;
    }
    
    final externalDir = await ExternalPath.getExternalStoragePublicDirectory(type);
    String fileDirectory = prependMoxxy ? path.join(externalDir, "Moxxy", conversationJid) : externalDir;
    final dir = Directory(fileDirectory);
    if (!(await dir.exists())) {
      await dir.create(recursive: true);
    }

    return path.join(fileDirectory, filename);
  }
  
  /// Returns true if the request was successful based on [statusCode].
  /// Based on https://developer.mozilla.org/en-US/docs/Web/HTTP/Status
  bool _isRequestOkay(int? statusCode) => statusCode != null && statusCode >= 200 && statusCode <= 399;
  
  Future<void> downloadFile(String url, int mId, String conversationJid, String? mimeGuess) async {
    _log.finest("Downloading $url");
    _tasks[url] = mId;
    _rateLimits[url] = 0;
    final uri = Uri.parse(url);
    final filename = uri.pathSegments.last;

    final downloadedPath = await _getDownloadPath(filename, conversationJid, mimeGuess);
    final response = await Dio().downloadUri(
      uri,
      downloadedPath,
      onReceiveProgress: (count, total) {
        final progress = count.toDouble() / total.toDouble();

        // TODO: Maybe rate limit harder
        if (progress * 100 >= _rateLimits[url]!) {
          _log.finest("Limit: ${_rateLimits[url]!}");
          sendEvent(
            DownloadProgressEvent(
              id: mId,
              progress: progress == 1 ? 0.99 : progress
            )
          );

          _rateLimits[url] = (progress * 10).round() * 10;
        }
      }
    );


    if (!_isRequestOkay(response.statusCode)) {
      // TODO: Error handling
      _log.warning("HTTP GET of $url returned ${response.statusCode}");
    }

    // Check the MIME type
    final notification = GetIt.I.get<NotificationsService>();
    final mime = mimeGuess ?? lookupMimeType(downloadedPath);

    if (mime != null && ["image/", "video/", "audio/"].any((e) => mime.startsWith(e))) {
      MediaScanner.loadMedia(path: downloadedPath);
    }

    final msg = await GetIt.I.get<DatabaseService>().updateMessage(
      id: _tasks[url]!,
      mediaUrl: downloadedPath,
      mediaType: mime
    );

    sendEvent(MessageUpdatedEvent(message: msg.copyWith(isDownloading: false)));

    if (notification.shouldShowNotification(msg.conversationJid)) {
      _log.finest("Creating notification with bigPicture $downloadedPath");
      await notification.showNotification(msg, "");
    }
    
    _tasks.remove(url);
    _rateLimits.remove(url);

    final conv = (await GetIt.I.get<DatabaseService>().getConversationByJid(conversationJid))!;
    final sharedMedium = await GetIt.I.get<DatabaseService>().addSharedMediumFromData(
      downloadedPath,
      msg.timestamp,
      mime: mime
    );
    final newConv = await GetIt.I.get<DatabaseService>().updateConversation(
      id: conv.id,
      sharedMedium: sharedMedium
    );
    sendEvent(ConversationUpdatedEvent(conversation: newConv));
  }

  /// Returns the size of the file at [url] in octets. If an error occurs or the server
  /// does not specify the Content-Length header, null is returned.
  /// See https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/Content-Length
  Future<FileMetadata> peekFile(String url) async {
    final response = await Dio().headUri(Uri.parse(url));

    if (!_isRequestOkay(response.statusCode)) return const FileMetadata();

    final contentLengthHeaders = response.headers["Content-Length"];
    final contentTypeHeaders = response.headers["Content-Type"];

    _log.finest("Peeking revealed: $contentLengthHeaders; $contentTypeHeaders");
    
    return FileMetadata(
      mime: contentTypeHeaders?.first,
      size: contentLengthHeaders != null && contentLengthHeaders.isNotEmpty ? int.parse(contentLengthHeaders.first) : null
    );
  }
}
