import 'package:flutter/material.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/widgets/chat/shared/base.dart';

class SharedAudioWidget extends StatelessWidget {
  const SharedAudioWidget(
    this.path, {
    this.onTap,
    this.onLongPress,
    this.borderColor,
    this.borderRadius = 3,
    this.size = sharedMediaContainerDimension,
    super.key,
  });
  final String path;
  final Color? borderColor;
  final void Function()? onTap;
  final void Function()? onLongPress;
  final double borderRadius;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SharedMediaContainer(
      Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          border: borderColor != null
              ? Border.all(
                  color: borderColor!,
                  width: 4,
                )
              : null,
        ),
        clipBehavior: Clip.hardEdge,
        child: Icon(
          Icons.music_note,
          size: size * 2 / 3,
        ),
      ),
      color: sharedMediaItemBackgroundColor,
      size: size,
      onTap: onTap,
      onLongPress: onLongPress,
    );
  }
}
