import 'dart:io';
import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/shared/models/message.dart';
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
  } else if (error is SaslError) {
    return t.errors.login.saslFailed;
  } else if (error is NoConnectionPossibleError) {
    return t.errors.login.noConnection;
  }

  return t.errors.login.unspecified;
}

HashFunction getStickerHashKeyType(Map<HashFunction, String> hashes) {
  if (hashes.containsKey(HashFunction.blake2b512)) {
    return HashFunction.blake2b512;
  } else if (hashes.containsKey(HashFunction.blake2b256)) {
    return HashFunction.blake2b256;
  } else if (hashes.containsKey(HashFunction.sha3_512)) {
    return HashFunction.sha3_512;
  } else if (hashes.containsKey(HashFunction.sha3_256)) {
    return HashFunction.sha3_256;
  } else if (hashes.containsKey(HashFunction.sha512)) {
    return HashFunction.sha512;
  } else if (hashes.containsKey(HashFunction.sha256)) {
    return HashFunction.sha256;
  }

  assert(false, 'No valid hash found');
  return HashFunction.sha256;
}

// TODO(PapaTutuWawa): Replace with getStrongestHash
String getStickerHashKey(Map<HashFunction, String> hashes) {
  final key = getStickerHashKeyType(hashes);
  return '$key:${hashes[key]}';
}

/// Return a human readable string describing an unrecoverable error event [event].
String getUnrecoverableErrorString(NonRecoverableErrorEvent event) {
  final error = event.error;
  if (error is SaslAccountDisabledError) {
    return t.errors.connection.saslAccountDisabled;
  } else if (error is SaslCredentialsExpiredError ||
      error is SaslNotAuthorizedError) {
    return t.errors.connection.saslInvalidCredentials;
  }

  return t.errors.connection.unrecoverable;
}

/// Creates the fallback body for quoted messages.
/// If the quoted message contains text, it simply quotes the text.
/// If it contains a media file, the messageEmoji (usually an emoji
/// representing the mime type) is shown together with the file size
/// (from experience this information is sufficient, as most clients show
/// the file size, and including time information might be confusing and a
/// potential privacy issue).
/// This information is complemented either the srcUrl or – if unavailable –
/// by the body of the quoted message. For non-media messages, we always use
/// the body as fallback.
String createFallbackBodyForQuotedMessage(Message quotedMessage) {
  if (quotedMessage.isMedia) {
    // Create formatted size string, if size is stored
    String quoteMessageSize;
    if (quotedMessage.fileMetadata!.size != null &&
        quotedMessage.fileMetadata!.size! > 0) {
      quoteMessageSize =
          '(${fileSizeToString(quotedMessage.fileMetadata!.size!)}) ';
    } else {
      quoteMessageSize = '';
    }

    // Create media url string, or use body if no srcUrl is stored
    String quotedMediaUrl;
    if (quotedMessage.fileMetadata!.sourceUrls != null &&
        quotedMessage.fileMetadata!.sourceUrls!.first.isNotEmpty) {
      quotedMediaUrl = '• ${quotedMessage.fileMetadata!.sourceUrls!.first}';
    } else if (quotedMessage.body.isNotEmpty) {
      quotedMediaUrl = '• ${quotedMessage.body}';
    } else {
      quotedMediaUrl = '';
    }

    // Concatenate emoji, size string, and media url and return
    return '${quotedMessage.messageEmoji} $quoteMessageSize$quotedMediaUrl';
  } else {
    return quotedMessage.body;
  }
}
