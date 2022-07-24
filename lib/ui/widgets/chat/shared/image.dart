import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxyv2/ui/service/thumbnail.dart';
import 'package:moxxyv2/ui/widgets/chat/shared/base.dart';
import 'package:moxxyv2/ui/widgets/chat/thumbnail.dart';
import 'package:open_file/open_file.dart';

class SharedImageWidget extends StatelessWidget {

  const SharedImageWidget(this.path, { Key? key }) : super(key: key);
  final String path;

  @override
  Widget build(BuildContext context) {
    return SharedMediaContainer(
      ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: ImageThumbnailWidget(
          path,
          (data) => Image.memory(data, fit: BoxFit.cover),
        ),
      ),
      onTap: () => OpenFile.open(path),
    );
  }
}
