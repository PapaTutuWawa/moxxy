import 'dart:io';
import 'package:moxxy_native/moxxy_native.dart';
import 'package:path/path.dart' as p;

/// Save the bytes [bytes] that represent the user's avatar under
/// the [cache directory/avatars/[hash].png.
/// [cache directory] is provided by path_provider.
Future<String> saveAvatarInCache(
  List<int> bytes,
  String hash,
  String jid,
  String? oldPath,
) async {
  final (cacheDirPath, avatarPath) = await getAvatarPath(hash);
  final cacheDir = Directory(cacheDirPath);
  if (!cacheDir.existsSync()) {
    await cacheDir.create(recursive: true);
  }

  if (oldPath != null) {
    final oldAvatar = File(oldPath);
    if (oldAvatar.existsSync()) await oldAvatar.delete();
  }

  await File(avatarPath).writeAsBytes(bytes);
  return avatarPath;
}

/// Returns the path where a user's avatar is saved. Note that this does not imply
/// the existence of an avatar.
Future<(String, String)> getAvatarPath(String hash) async {
  final rawCacheDir = await MoxxyPlatformApi().getCacheDataPath();
  final avatarCacheDir = p.join(rawCacheDir, 'avatars');
  return (avatarCacheDir, p.join(avatarCacheDir, '$hash.png'));
}
