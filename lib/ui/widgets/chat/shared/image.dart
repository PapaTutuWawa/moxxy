import 'dart:io';
import 'package:flutter/material.dart';
import 'package:moxxyv2/ui/widgets/chat/shared/base.dart';

class SharedImageWidget extends StatelessWidget {
  const SharedImageWidget(
    this.path, {
    this.onTap,
    this.borderColor,
    this.child,
    this.borderRadius = 10,
    this.size = sharedMediaContainerDimension,
    super.key,
  });
  final String path;
  final Color? borderColor;
  final void Function()? onTap;
  final Widget? child;
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
          image: DecorationImage(
            fit: BoxFit.cover,
            image: FileImage(
              File(path),
              scale: 4,
            ),
          ),
        ),
        clipBehavior: Clip.hardEdge,
        child: child,
      ),
      borderRadius: borderRadius,
      color: Colors.transparent,
      size: size,
      onTap: onTap,
    );
  }
}
