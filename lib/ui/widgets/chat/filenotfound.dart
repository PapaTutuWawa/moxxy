import 'package:flutter/material.dart';

class FileNotFound extends StatelessWidget {
  const FileNotFound({super.key});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      // TODO(Unknown): Maybe make this prettier
      decoration: const BoxDecoration(
        color: Colors.black45,
        borderRadius: BorderRadius.all(Radius.circular(18)),
      ),
      child: Text(
        'File not available',
        style: TextStyle(
          color: Colors.red[600],
        ),
      ),
    );
  }
}
