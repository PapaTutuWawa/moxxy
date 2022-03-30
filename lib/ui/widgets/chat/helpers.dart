import "dart:ui";
import "dart:math";

import "package:moxxyv2/shared/models/message.dart";

/// Extract the size of the thumbnail from a message
Size getThumbnailSize(Message message, double maxWidth) {
  final size = message.thumbnailDimensions?.split("x");
  double width = maxWidth;
  double height = maxWidth;
  if (size != null) {
    final dimWidth = int.parse(size[0]).toDouble();
    final dimHeight = int.parse(size[1]).toDouble();
    width = min(dimWidth, maxWidth);
    height = ((width / dimWidth) * dimHeight);
  }

  return Size(width, height);
}
