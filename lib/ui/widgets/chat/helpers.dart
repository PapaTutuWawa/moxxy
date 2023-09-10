import 'dart:math';
import 'dart:ui';
import 'package:moxxy_native/moxxy_native.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/models/message.dart';

/// Calculate the transformed size of a media message based on its stored
/// dimensions.
Size getMediaSize(Message message, double maxWidth) {
  final mediaWidth = message.fileMetadata?.width?.toDouble();
  final mediaHeight = message.fileMetadata?.height?.toDouble();

  var width = maxWidth;
  var height = maxWidth;
  if (mediaWidth != null && mediaHeight != null) {
    width = min(mediaWidth, maxWidth);
    height = (width / mediaWidth) * mediaHeight;
  }

  return Size(width, height);
}

/// Request the media download from a message.
void requestMediaDownload(Message message) {
  getForegroundService().send(
    RequestDownloadCommand(message: message),
    awaitable: false,
  );
}
