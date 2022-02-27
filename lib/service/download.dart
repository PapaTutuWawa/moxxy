import "dart:async";
import "dart:io";

import "package:moxxyv2/shared/events.dart";
import "package:moxxyv2/service/database.dart";
import "package:moxxyv2/service/notifications.dart";

import "package:logging/logging.dart";
import "package:dio/dio.dart";
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
    final filename = uri.pathSegments.last;

    Directory tempDir = await getTemporaryDirectory();
    final downloadedPath = path.join(tempDir.path, filename);
    final response = await Dio().downloadUri(
      uri,
      downloadedPath,
      onReceiveProgress: (count, total) {
        // TODO: Maybe limit this a bit
        sendData(DownloadProgressEvent(
            id: mId,
            progress: count.toDouble() / total.toDouble()
        ));
      }
    );


    if (response.statusCode != 200) {
      // TODO: I think there are more codes that are okay.
      //       => Check and change the .warning to a .severe
      _log.warning("HTTP GET of $url returned ${response.statusCode}");
    }

    // Check the MIME type
    // TODO: Handle non-image and non-video files and files whose mime type cannot be determined
    // TODO: add_to_gallery currently doesn't allow us to save videos to the gallery
    //       https://github.com/flowmobile/add_to_gallery/issues/2#issuecomment-869477521
    final f = File(downloadedPath);
    final notification = GetIt.I.get<NotificationsService>();
    final mime = lookupMimeType(f.path)!;
    if (mime.startsWith("image/")) {
      final galleryFile = await AddToGallery.addToGallery(
        originalFile: f,
        albumName: "Moxxy Images",
        deleteOriginalFile: true
      );

      final msg = await GetIt.I.get<DatabaseService>().updateMessage(
        id: _tasks[url]!,
        mediaUrl: galleryFile.path,
        mediaType: mime
      );
      
      sendData(MessageUpdatedEvent(message: msg));

      if (notification.shouldShowNotification(msg.conversationJid)) {
        _log.finest("Creating notification with bigPicture ${galleryFile.path}");
        await notification.showNotification(msg, "");
      }
      
      _tasks.remove(url);
    } else {
      final msg = await GetIt.I.get<DatabaseService>().updateMessage(
        id: _tasks[url]!,
        mediaUrl: f.path,
        mediaType: mime
      );
      
      sendData(MessageUpdatedEvent(message: msg.copyWith(isDownloading: false)));

      if (notification.shouldShowNotification(msg.conversationJid)) {
        // TODO: This is most likely wrong
        _log.finest("Creating notification with bigPicture ${f.path}");
        await notification.showNotification(msg, "");
      }
      
      _tasks.remove(url);
    }    
  }
}
