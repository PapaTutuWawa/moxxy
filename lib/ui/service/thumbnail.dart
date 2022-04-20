import "dart:typed_data";
import "dart:isolate";

import "package:moxxyv2/shared/cache.dart";

import "package:logging/logging.dart";
import "package:video_thumbnail/video_thumbnail.dart";
import "package:flutter_image_compress/flutter_image_compress.dart";
import "package:flutter_isolate/flutter_isolate.dart";
import "package:synchronized/synchronized.dart";

Future<void> _generateVideoThumbnail(List<dynamic> values) async {
  final port = values[0];
  final path = values[1];
  final data = await VideoThumbnail.thumbnailData(
    video: path,
    quality: 75,
  );

  port.send(data!);
}

Future<void> _generateImageThumbnail(List<dynamic> values) async {
  final port = values[0];
  final path = values[1];
  final data = await FlutterImageCompress.compressWithFile(
    path,
    quality: 75,
  );

  port.send(data!);
}

class ThumbnailCacheService {
  final Logger _log;

  // Asset path -> decoded data
  final LRUCache<String, Uint8List> _thumbnailCache;
  final Lock _cacheLock;

  ThumbnailCacheService()
  // TODO: Maybe raise this limit
  : _thumbnailCache = LRUCache(200),
    _cacheLock = Lock(),
    _log = Logger("ThumbnailCacheService");

  Future<Uint8List> getVideoThumbnail(String path) async {
    Uint8List? data;

    // Turning this into a critical section allows us to prevent multiple calls to the
    // isolate in case we generate thumbnails for the same path multiple times.
    _log.fine("getVideoThumbnail: Waiting to acquire lock...");
    await _cacheLock.synchronized(() async {
        _log.fine("getVideoThumbnail: Done");
        if (_thumbnailCache.inCache(path)) {
          _log.finest("Thumbnail data is in cache!");
          _log.finest("getVideoThumbnail: Releasing lock");
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
        _log.finest("getVideoThumbnail: Releasing lock");
    });

    return data!;
  }

  Future<Uint8List> getImageThumbnail(String path) async {
    Uint8List? data;

    // Turning this into a critical section allows us to prevent multiple calls to the
    // isolate in case we generate thumbnails for the same path multiple times.
    _log.finest("getImageThumbnail: Waiting to aquire lock...");
    await _cacheLock.synchronized(() async {
        _log.finest("getImageThumbnail: Done");
        if (_thumbnailCache.inCache(path)) {
          _log.finest("Thumbnail data is in cache!");
          data = _thumbnailCache.getValue(path)!;
          _log.finest("getImageThumbnail: Releasing lock");
          return;
        }

        _log.finest("Thumbnail data not in cache generating...");

        final port = ReceivePort();
        final isolate = await FlutterIsolate.spawn(_generateImageThumbnail, [ port.sendPort, path ]);
        data = (await port.first) as Uint8List;
        isolate.kill(priority: Isolate.immediate);
        
        _log.finest("Generation done.");
        _thumbnailCache.cache(path, Uint8List.fromList(data!));
        _log.finest("Returning.");
        _log.finest("getImageThumbnail: Releasing lock");
    });

    return data!;
  }
}
