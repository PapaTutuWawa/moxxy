import 'package:flutter/material.dart';
import 'package:moxxyv2/ui/widgets/chat/shared/base.dart';
import 'package:moxxyv2/ui/widgets/chat/video_thumbnail.dart';

class SharedVideoWidget extends StatelessWidget {
  const SharedVideoWidget(
    this.path,
    this.conversationJid, {
      this.onTap,
      this.borderColor,
      this.child,
      this.size = sharedMediaContainerDimension,
      this.borderRadius = 10,
      super.key,
    }
  );
  final String path;
  final String conversationJid;
  final Color? borderColor;
  final void Function()? onTap;
  final Widget? child;
  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    return SharedMediaContainer(
      VideoThumbnail(
        path: path,
        conversationJid: conversationJid,
        size: Size(
          size,
          size,
        ),
        borderRadius: BorderRadius.circular(borderRadius), 
      ),
      size: size,
      onTap: onTap,
    );
  }
}
