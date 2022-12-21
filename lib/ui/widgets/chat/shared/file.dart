import 'package:flutter/material.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/widgets/chat/shared/base.dart';

class SharedFileWidget extends StatelessWidget {
  const SharedFileWidget(
    this.path, {
      this.onTap,
      this.borderRadius = 10,
      this.size = sharedMediaContainerDimension,
      super.key,
    }
  );
  final String path;
  final void Function()? onTap;
  final double borderRadius;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SharedMediaContainer(
      Icon(
        Icons.file_present,
        size: size * 2/3,
      ),
      color: sharedMediaItemBackgroundColor,
      borderRadius: borderRadius,
      size: size,
      onTap: onTap,
    );
  }
}
