import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';
import 'package:native_imaging/native_imaging.dart' as native;

/// Generate a blurhash thumbnail using native_imaging.
Future<String?> generateBlurhashThumbnail(String path) async {
  await native.init();

  final bytes = await File(path).readAsBytes();

  native.Image image;
  try {
    final dartCodec = await instantiateImageCodec(bytes);
    final dartFrame = await dartCodec.getNextFrame();
    final rgbaData = await dartFrame.image.toByteData();
    if (rgbaData == null) return null;

    final width = dartFrame.image.width;
    final height = dartFrame.image.height;

    dartFrame.image.dispose();
    dartCodec.dispose();

    image = native.Image.fromRGBA(
      width,
      height,
      Uint8List.view(
        rgbaData.buffer,
        rgbaData.offsetInBytes,
        rgbaData.lengthInBytes,
      ),
    );
  } catch (_) {
    // TODO(PapaTutuWawa): Log error
    return null;
  }

  final blurhash = image.toBlurhash(3, 3);
  image.free();
  return blurhash;
}
