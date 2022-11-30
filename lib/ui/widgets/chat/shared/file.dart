import 'package:better_open_file/better_open_file.dart';
import 'package:flutter/material.dart';
import 'package:moxxyv2/ui/widgets/chat/shared/base.dart';

class SharedFileWidget extends StatelessWidget {
  const SharedFileWidget(
    this.path, {
      this.enableOnTap = true,
      this.borderRadius = 10,
      this.size = sharedMediaContainerDimension,
      super.key,
    }
  );
  final String path;
  final bool enableOnTap;
  final double borderRadius;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SharedMediaContainer(
      DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          color: Colors.white60,
        ),
        child: Icon(
          Icons.file_present,
          size: size * 2/3,
        ),
      ),
      size: size,
      onTap: enableOnTap ?
        () => OpenFile.open(path) :
        null,
    );
  }
}
