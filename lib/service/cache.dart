import 'package:moxxy_native/moxxy_native.dart';
import 'package:path/path.dart' as p;

/// Computes the path to a subdirectory [subdirectory] inside Moxxy's
/// cache directory. Note that this method does not guarantee the returned
/// path's existence.
Future<String> computeCacheDirectoryPath(String subdirectory) async {
  return p.join(
    await MoxxyPlatformApi().getCacheDataPath(),
    subdirectory,
  );
}
