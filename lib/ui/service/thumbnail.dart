import 'dart:isolate';
import 'dart:typed_data';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_isolate/flutter_isolate.dart';
import 'package:logging/logging.dart';
import 'package:moxxyv2/shared/cache.dart';
import 'package:moxxyv2/shared/semaphore.dart';
import 'package:video_thumbnail/video_thumbnail.dart';

Future<void> _generateVideoThumbnail(List<dynamic> values) async {
  final port = values[0] as SendPort;
  final path = values[1] as String;

  try {
    final data = await VideoThumbnail.thumbnailData(
      video: path,
      quality: 75,
    );

    port.send(data);
  } catch (_) {
    port.send(Uint8List(0));
  }
}

Future<void> _generateImageThumbnail(List<dynamic> values) async {
  final port = values[0] as SendPort;
  final path = values[1] as String;
  final data = await FlutterImageCompress.compressWithFile(
    path,
    quality: 75,
  );

  port.send(data);
}

class ThumbnailCacheService {

  ThumbnailCacheService()
  // TODO(Unknown): Maybe raise this limit
  : _thumbnailCache = LRUCache(200),
    _cacheSemaphore = Semaphore(8),
    _log = Logger('ThumbnailCacheService');
  final Logger _log;

  // Asset path -> decoded data
  final LRUCache<String, Uint8List> _thumbnailCache;
  final Semaphore _cacheSemaphore;

  Future<Uint8List> getVideoThumbnail(String path) async {
    // Turning this into a critical section allows us to prevent multiple calls to the
    // isolate in case we generate thumbnails for the same path multiple times.
    _log.fine('getVideoThumbnail: Waiting to acquire semaphore...');
    await _cacheSemaphore.aquire();
    _log.fine('getVideoThumbnail: Done');
    if (_thumbnailCache.inCache(path)) {
      _log.finest('Thumbnail data is in cache!');
      await _cacheSemaphore.release();
      _log.finest('getVideoThumbnail: Released semaphore');

      return _thumbnailCache.getValue(path)!;
    }

    _log.finest('Thumbnail data not in cache generating...');

    final port = ReceivePort();
    final isolate = await FlutterIsolate.spawn(_generateVideoThumbnail, [ port.sendPort, path ]);
    final data = await port.first as Uint8List;
    isolate.kill(priority: Isolate.immediate);
    
    _log.finest('Generation done.');
    _thumbnailCache.cache(path, Uint8List.fromList(data));

    await _cacheSemaphore.release();
    _log.finest('getVideoThumbnail: Released semaphore');

    return data;
  }

  Future<Uint8List> getImageThumbnail(String path) async {
    // Turning this into a critical section allows us to prevent multiple calls to the
    // isolate in case we generate thumbnails for the same path multiple times.
    _log.finest('getImageThumbnail: Waiting to aquire semaphore...');
    await _cacheSemaphore.aquire();
    _log.finest('getImageThumbnail: Done');
    if (_thumbnailCache.inCache(path)) {
      _log.finest('Thumbnail data is in cache!');
      await _cacheSemaphore.release();
      _log.finest('getImageThumbnail: Released semaphore');

      return _thumbnailCache.getValue(path)!;
    }

    _log.finest('Thumbnail data not in cache generating...');

    final port = ReceivePort();
    final isolate = await FlutterIsolate.spawn(_generateImageThumbnail, [ port.sendPort, path ]);
    final data = await port.first as Uint8List;
    isolate.kill(priority: Isolate.immediate);
    
    _log.finest('Generation done.');
    _thumbnailCache.cache(path, Uint8List.fromList(data));
    await _cacheSemaphore.release();
    _log.finest('getImageThumbnail: Released semaphore');

    return data;
  }
}
