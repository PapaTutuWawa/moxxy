import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:native_imaging/native_imaging.dart' as native;

Future<String?> _generateBlurhashThumbnailImpl(String path) async {
  await native.init();

  final bytes = await File(path).readAsBytes();

  native.Image image;
  int width;
  int height;
  try {
    final dartCodec = await instantiateImageCodec(bytes);
    final dartFrame = await dartCodec.getNextFrame();
    final rgbaData = await dartFrame.image.toByteData();
    if (rgbaData == null) return null;

    width = dartFrame.image.width;
    height = dartFrame.image.height;

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

  // Scale the image down as recommended by
  // https://github.com/woltapp/blurhash#how-fast-is-encoding-decoding
  final scaled = image.resample(
    20,
    (height * (width / height)).toInt(),
    native.Transform.bilinear,
  );

  // Calculate the blurhash
  final blurhash = scaled.toBlurhash(3, 3);

  // Free resources
  image.free();
  scaled.free();
  return blurhash;
}

/// Generate a blurhash thumbnail using native_imaging.
Future<String?> generateBlurhashThumbnail(String path) async {
  return compute(_generateBlurhashThumbnailImpl, path);
}

/// Turn a XmppError into its corresponding translated string.
String xmppErrorToTranslatableString(XmppError error) {
  if (error is StartTLSFailedError) {
    return t.errors.login.startTlsFailed;
  } else if (error is SaslFailedError) {
    return t.errors.login.saslFailed;
  } else if (error is NoConnectionError) {
    return t.errors.login.noConnection;
  }
  
  return t.errors.login.unspecified;
}
