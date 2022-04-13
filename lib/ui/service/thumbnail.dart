import "dart:typed_data";
import "dart:isolate";

import "package:logging/logging.dart";
import "package:video_thumbnail/video_thumbnail.dart";
import "package:flutter_isolate/flutter_isolate.dart";

Future<void> _generateVideoThumbnail(List<dynamic> values) async {
  final data = await VideoThumbnail.thumbnailData(
    video: values[1],
    quality: 75,
  );

  values[0].send(data!);
}

class ThumbnailCacheService {
  final Logger _log;

  // TODO: Implement some eviction policy
  // Asset path -> decoded data
  final Map<String, Uint8List> _thumbnailCache;

  ThumbnailCacheService()
  : _thumbnailCache = {},
      _log = Logger("ThumbnailCacheService");

  bool isCached(String path) => _thumbnailCache.containsKey(path);

  // TODO: Maybe lock this function to prevent the same path to be generated over and over
  Future<Uint8List> getVideoThumbnail(String path) async {
    if (isCached(path)) {
      _log.finest("Thumbnail data is in cache!");
      return _thumbnailCache[path]!;
    }

    _log.finest("Thumbnail data not in cache generating...");

    final port = ReceivePort();
    final isolate = await FlutterIsolate.spawn(_generateVideoThumbnail, [ port.sendPort, path ]);
    final data = (await port.first) as Uint8List;
    isolate.kill(priority: Isolate.immediate);
    
    _log.finest("Generation done.");
    _thumbnailCache[path] = Uint8List.fromList(data);
    _log.finest("Returning.");
    return data;
  }
}
