import 'dart:math';
import 'dart:ui';

import 'package:moxplatform/moxplatform.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/models/message.dart';

/// Extract the size of the thumbnail from a message
Size getThumbnailSize(Message message, double maxWidth) {
  final size = message.thumbnailDimensions?.split('x');
  var width = maxWidth;
  var height = maxWidth;
  if (size != null) {
    final dimWidth = int.parse(size[0]).toDouble();
    final dimHeight = int.parse(size[1]).toDouble();
    width = min(dimWidth, maxWidth);
    height = (width / dimWidth) * dimHeight;
  }

  return Size(width, height);
}

/// Request the media download from a message.
void requestMediaDownload(Message message) {
  MoxplatformPlugin.handler.getDataSender().sendData(
    RequestDownloadCommand(message: message),
    awaitable: false,
  );
}
