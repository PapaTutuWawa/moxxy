import "package:moxxyv2/ui/widgets/chat/shared/base.dart";

import "package:flutter/material.dart";
import "package:open_file/open_file.dart";

class SharedFileWidget extends StatelessWidget {
  final String path;

  const SharedFileWidget(this.path, { Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SharedMediaContainer(
      Container(
        child: const Icon(
          Icons.file_present,
          size: 48.0
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white60
        )
      ),
      onTap: () => OpenFile.open(path)
    );
  }
}
