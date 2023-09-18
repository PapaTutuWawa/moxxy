import 'dart:io';
import 'package:flutter/material.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/shared/thumbnails/helpers.dart';
import 'package:moxxyv2/ui/widgets/chat/playbutton.dart';
import 'package:moxxyv2/ui/widgets/shimmer.dart';

Future<String?> _videoThumbnailWrapper(String path, String mime) async {
  if (!canGenerateVideoThumbnail(mime)) return null;

  return maybeGenerateVideoThumbnail(path);
}

class VideoThumbnail extends StatelessWidget {
  const VideoThumbnail({
    required this.path,
    required this.conversationJid,
    required this.size,
    required this.borderRadius,
    required this.mime,
    super.key,
  });
  final String path;
  final String conversationJid;
  final Size size;
  final BorderRadius borderRadius;
  final String mime;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _videoThumbnailWrapper(path, mime),
      builder: (context, snapshot) {
        Widget widget;
        if (snapshot.hasData && snapshot.data != null) {
          widget = Image.file(
            File(snapshot.data!),
            fit: BoxFit.cover,
          );
        } else if (snapshot.hasError ||
            snapshot.hasData && snapshot.data == null) {
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
          child: Stack(
            children: [
              Positioned.fill(child: widget),
              const Positioned(
                child: PlayButton(),
              ),
            ],
          ),
        );
      },
    );
  }
}
