import "dart:io";

import "package:moxxyv2/ui/constants.dart";
import "package:moxxyv2/ui/widgets/chat/shared/base.dart";

import "package:flutter/material.dart";

class SharedImageWidget extends StatelessWidget {
  final String path;
  //final void Function()? onTap;

  const SharedImageWidget(this.path, { Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SharedMediaContainer(
      Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          image: DecorationImage(
            fit: BoxFit.cover,
            image: FileImage(File(path))
          )
        )
      )
    );
  }
}
