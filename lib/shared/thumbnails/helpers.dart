import 'dart:io';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:moxxy_native/moxxy_native.dart';
import 'package:path/path.dart' as p;

Future<String> getVideoThumbnailPath(String path) async {
  final tempDir = await MoxxyPlatformApi().getCacheDataPath();
  final thumbnailFilenameNoExtension = p.withoutExtension(
    p.basename(path),
  );
  final thumbnailFilename = '$thumbnailFilenameNoExtension.jpg';
  final thumbnailDirectory = p.join(
    tempDir,
    'thumbnails',
  );
  return p.join(thumbnailDirectory, thumbnailFilename);
}

/// Generate a thumbnail file (JPEG) for the video at [path].
/// If the thumbnail already exists, then just its path is returned. If not, then
/// it gets generated first.
Future<String?> maybeGenerateVideoThumbnail(
  String path,
) async {
  final thumbnailPath = await getVideoThumbnailPath(path);
  final thumbnailDirectory = p.dirname(thumbnailPath);
  final dir = Directory(thumbnailDirectory);
  if (!dir.existsSync()) await dir.create(recursive: true);
  final file = File(thumbnailPath);
  if (file.existsSync()) return thumbnailPath;

  final success = await MoxxyMediaApi().generateVideoThumbnail(path, thumbnailPath, 720);
  if (!success) {
    GetIt.I.get<Logger>().warning('Failed to generate thumbnail for $path');
    return null;
  }

  return thumbnailPath;
}
