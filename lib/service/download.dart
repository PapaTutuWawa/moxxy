import "dart:async";
import "dart:io";

import "package:moxxyv2/shared/events.dart";
import "package:moxxyv2/service/database.dart";
import "package:moxxyv2/service/notifications.dart";

import "package:logging/logging.dart";
import "package:http/http.dart" as http;
import "package:path_provider/path_provider.dart";
import "package:path/path.dart" as path;
import "package:get_it/get_it.dart";
import "package:mime/mime.dart";
import "package:add_to_gallery/add_to_gallery.dart";

// TODO: Make this more reliable:
//       - Retry if a download failed, e.g. because we lost internet connection
//       - hold a queue of files to download
class DownloadService {
  final void Function(BaseIsolateEvent) sendData;

  final Logger _log;
  // Map the URL to download to the message id of the message we need to update
  // NOTE: This will be useful when we implement a queue 
  final Map<String, int> _tasks;

  DownloadService(this.sendData) : _tasks = {}, _log = Logger("DownloadService");

  Future<void> downloadFile(String url, int mId) async {
    _log.finest("Downloading $url");
    _tasks[url] = mId;
    final uri = Uri.parse(url);
    final response = await http.get(uri);

    if (response.statusCode != 200) {
      // TODO: I think there are more codes that are okay.
      //       => Check and change the .warning to a .severe
      _log.warning("HTTP GET of $url returned ${response.statusCode}");
    }

    Directory tempDir = await getTemporaryDirectory();
    File f = File(path.join(tempDir.path, uri.pathSegments.last));
    await f.writeAsBytes(response.bodyBytes);

    // Check the MIME type
    // TODO: Handle non-image and non-video files and files whose mime type cannot be determined
    // TODO: add_to_gallery currently doesn't allow us to save videos to the gallery
    //       https://github.com/flowmobile/add_to_gallery/issues/2#issuecomment-869477521
    final mime = lookupMimeType(f.path)!;
    if (mime.startsWith("image/")) {
      final galleryFile = await AddToGallery.addToGallery(
        originalFile: f,
        albumName: "Moxxy Images",
        deleteOriginalFile: true
      );

      final msg = await GetIt.I.get<DatabaseService>().updateMessage(
        id: _tasks[url]!,
        mediaUrl: galleryFile.path
      );
      
      sendData(MessageUpdatedEvent(message: msg));

      _log.finest("Creating notification with bigPicture ${galleryFile.path}");
      await GetIt.I.get<NotificationsService>().showNotification(msg, "");
      
      _tasks.remove(url);
    } else {
      final msg = await GetIt.I.get<DatabaseService>().updateMessage(
        id: _tasks[url]!,
        mediaUrl: f.path
      );
      
      sendData(MessageUpdatedEvent(message: msg));

      _log.finest("Creating notification with bigPicture ${f.path}");
      await GetIt.I.get<NotificationsService>().showNotification(msg, "");
      
      _tasks.remove(url);
    }    
  }

  /// Performs an HTTP HEAD request to figure out how large the file is we
  /// are about to download.
  /// Returns the size in bytes or -1 if the server specified no Content-Length header.
  Future<int> peekFileSize(String url) async {
    final response = await http.head(Uri.parse(url));

    return int.parse(response.headers["Content-Length"] ?? "-1");
  }
}
