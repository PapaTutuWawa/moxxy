import 'dart:io';
import 'package:flutter/material.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/ui/widgets/shimmer.dart';

class VideoThumbnail extends StatelessWidget {
  const VideoThumbnail({
    required this.path,
    required this.conversationJid,
    required this.size,
    required this.borderRadius,
    super.key,
  });
  final String path;
  final String conversationJid;
  final Size size;
  final BorderRadius borderRadius;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: getVideoThumbnailPath(path, conversationJid),
      builder: (context, snapshot) {
        Widget widget;
        if (snapshot.hasData) {
          widget = Image.file(
            File(snapshot.data!),
            fit: BoxFit.cover,
          );
        } else if (snapshot.hasError) {
          widget = SizedBox(
            width: size.width,
            height: size.height,
            child: const ColoredBox(
              color: Colors.black,
            ),
          );
        } else {
          widget = SizedBox(
            width: size.width,
            height: size.height,
            child: const ShimmerWidget(),
          );
        }

        return ClipRRect(
          borderRadius: borderRadius,
          child: widget,
        );
      },
    );
  }
}
