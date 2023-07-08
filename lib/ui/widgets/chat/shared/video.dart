import 'package:flutter/material.dart';
import 'package:moxxyv2/ui/widgets/chat/shared/base.dart';
import 'package:moxxyv2/ui/widgets/chat/video_thumbnail.dart';

class SharedVideoWidget extends StatelessWidget {
  const SharedVideoWidget(
    this.path,
    this.conversationJid,
    this.mime, {
    this.onTap,
    this.onLongPress,
    this.borderColor,
    this.child,
    this.size = sharedMediaContainerDimension,
    this.borderRadius = 3,
    super.key,
  });
  final String path;
  final String conversationJid;
  final String mime;
  final Color? borderColor;
  final void Function()? onTap;
  final void Function()? onLongPress;
  final Widget? child;
  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return SharedMediaContainer(
      VideoThumbnail(
        path: path,
        conversationJid: conversationJid,
        mime: mime,
        size: Size(
          size,
          size,
        ),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      borderRadius: borderRadius,
      color: Colors.transparent,
      size: size,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}
