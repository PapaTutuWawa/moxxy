import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';

class BlurhashChatWidget extends StatelessWidget {
  const BlurhashChatWidget({
    required this.borderRadius,
    required this.width,
    required this.height,
    required this.thumbnailData,
    this.child,
    super.key,
  });
  final BorderRadius borderRadius;
  final int width;
  final int height;
  final String thumbnailData;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: Stack(
        alignment: Alignment.center,
        children: [
          ClipRRect(
            borderRadius: borderRadius,
            child: SizedBox(
              width: width.toDouble(),
              height: height.toDouble(),
              child: BlurHash(
                hash: thumbnailData,
                decodingWidth: width,
                decodingHeight: height,
              ),
            ),
          ),
          if (child != null) child!,
        ],
      ),
    );
  }
}
