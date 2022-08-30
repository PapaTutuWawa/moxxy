import 'package:better_open_file/better_open_file.dart';
import 'package:flutter/material.dart';
import 'package:moxxyv2/ui/widgets/chat/shared/base.dart';

class SharedFileWidget extends StatelessWidget {

  const SharedFileWidget(this.path, { Key? key }) : super(key: key);
  final String path;

  @override
  Widget build(BuildContext context) {
    return SharedMediaContainer(
      DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white60,
        ),
        child: const Icon(
          Icons.file_present,
          size: 48,
        ),
      ),
      onTap: () => OpenFile.open(path),
    );
  }
}
