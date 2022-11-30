import 'package:flutter/material.dart';
import 'package:moxxyv2/ui/widgets/chat/shared/base.dart';

class SharedAudioWidget extends StatelessWidget {
  const SharedAudioWidget(
    this.path, {
      this.onTap,
      this.borderColor,
      this.borderRadius = 10,
      this.size = sharedMediaContainerDimension,
      super.key,
    }
  );
  final String path;
  final Color? borderColor;
  final void Function()? onTap;
  final double borderRadius;
  final double size;
  
  @override
  Widget build(BuildContext context) {
    return SharedMediaContainer(
      Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          color: Colors.white60,
          border: borderColor != null ? Border.all(
            color: borderColor!,
            width: 4,
          ) : null,
        ),
        clipBehavior: Clip.hardEdge,
        child: Icon(
          Icons.music_note,
          size: size * 2/3,
        ),
      ),
      size: size,
      onTap: onTap,
    );
  }
}
