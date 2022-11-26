import 'dart:io';
import 'package:flutter/material.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/ui/widgets/chat/shared/base.dart';

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
      FutureBuilder<String>(
        future: getVideoThumbnailPath(path, conversationJid),
        builder: (context, snapshot) {
          Widget widget;
          if (snapshot.hasData) {
            widget = Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(borderRadius),
                image: DecorationImage(
                  fit: BoxFit.cover,
                  image: FileImage(File(snapshot.data!)),
                ),
              ),
              clipBehavior: Clip.hardEdge,
              child: child,
            );
          } else {
            widget = const CircularProgressIndicator();
          }

          return widget;
        },
      ),
      size: size,
      onTap: onTap,
    );
  }
}
