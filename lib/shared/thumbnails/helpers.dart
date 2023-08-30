import 'dart:io';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:moxplatform/moxplatform.dart';
import 'package:path/path.dart' as p;

/// Generate a thumbnail file (JPEG) for the video at [path].
/// If the thumbnail already exists, then just its path is returned. If not, then
/// it gets generated first.
Future<String?> maybeGenerateVideoThumbnail(
  String path,
) async {
  final tempDir = await MoxplatformPlugin.platform.getCacheDataPath();
  final thumbnailFilenameNoExtension = p.withoutExtension(
    p.basename(path),
  );
  final thumbnailFilename = '$thumbnailFilenameNoExtension.jpg';
  final thumbnailDirectory = p.join(
    tempDir,
    'thumbnails',
  );
  final thumbnailPath = p.join(thumbnailDirectory, thumbnailFilename);

  final dir = Directory(thumbnailDirectory);
  if (!dir.existsSync()) await dir.create(recursive: true);
  final file = File(thumbnailPath);
  if (file.existsSync()) return thumbnailPath;

  final success = await MoxplatformPlugin.platform
      .generateVideoThumbnail(path, thumbnailPath, 720);
  if (!success) {
    GetIt.I.get<Logger>().warning('Failed to generate thumbnail for $path');
    return null;
  }

  return thumbnailPath;
}
