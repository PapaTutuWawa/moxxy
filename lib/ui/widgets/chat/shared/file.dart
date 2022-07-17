import 'package:flutter/material.dart';
import 'package:moxxyv2/ui/widgets/chat/shared/base.dart';
import 'package:open_file/open_file.dart';

class SharedFileWidget extends StatelessWidget {

  const SharedFileWidget(this.path, { Key? key }) : super(key: key);
  final String path;

  @override
  Widget build(BuildContext context) {
    return SharedMediaContainer(
      Container(
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
