import "dart:typed_data";
import "dart:isolate";

import "package:moxxyv2/shared/cache.dart";

import "package:logging/logging.dart";
import "package:video_thumbnail/video_thumbnail.dart";
import "package:flutter_isolate/flutter_isolate.dart";
import "package:mutex/mutex.dart";

Future<void> _generateVideoThumbnail(List<dynamic> values) async {
  final data = await VideoThumbnail.thumbnailData(
    video: values[1],
    quality: 75,
  );

  values[0].send(data!);
}

class ThumbnailCacheService {
  final Logger _log;

  // Asset path -> decoded data
  final LRUCache<String, Uint8List> _thumbnailCache;
  final Mutex _cacheMutex;

  ThumbnailCacheService()
  // TODO: Maybe raise this limit
  : _thumbnailCache = LRUCache(200),
    _cacheMutex = Mutex(),
    _log = Logger("ThumbnailCacheService");

  Future<Uint8List> getVideoThumbnail(String path) async {
    Uint8List? data;

    // Turning this into a critical section allows us to prevent multiple calls to the
    // isolate in case we generate thumbnails for the same path multiple times.
    await _cacheMutex.protect(() async {
        if (_thumbnailCache.inCache(path)) {
          _log.finest("Thumbnail data is in cache!");
          data = _thumbnailCache.getValue(path)!;
          return;
        }

        _log.finest("Thumbnail data not in cache generating...");

        final port = ReceivePort();
        final isolate = await FlutterIsolate.spawn(_generateVideoThumbnail, [ port.sendPort, path ]);
        data = (await port.first) as Uint8List;
        isolate.kill(priority: Isolate.immediate);
        
        _log.finest("Generation done.");
        _thumbnailCache.cache(path, Uint8List.fromList(data!));
        _log.finest("Returning.");
    });

    return data!;
  }
}
