import 'dart:io';
import 'package:flutter/material.dart';
import 'package:moxxyv2/ui/widgets/chat/shared/base.dart';

class SharedImageWidget extends StatelessWidget {

  const SharedImageWidget(this.path, this.onTap, { this.borderColor, this.child, Key? key }) : super(key: key);
  final String path;
  final Color? borderColor;
  final void Function() onTap;
  final Widget? child;
  
  @override
  Widget build(BuildContext context) {
    return SharedMediaContainer(
      Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: borderColor != null ? Border.all(
            color: borderColor!,
            width: 4,
          ) : null,
          image: DecorationImage(
            fit: BoxFit.cover,
            image: FileImage(File(path)),
          ),
        ),
        clipBehavior: Clip.hardEdge,
        child: child,
      ),
      onTap: onTap,
    );
  }
}
