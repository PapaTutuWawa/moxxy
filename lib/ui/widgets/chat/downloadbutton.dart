import 'package:flutter/material.dart';

class DownloadButton extends StatelessWidget {

  const DownloadButton({ required this.onPressed, Key? key }) : super(key: key);
  final void Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return Ink(
      decoration: const ShapeDecoration(
        color: Colors.black45,
        shape: CircleBorder(),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(100),
          color: Colors.black.withAlpha(150),
        ),
        child: IconButton(
          icon: const Icon(Icons.download),
          iconSize: 64,
          color: Colors.white,
          onPressed: onPressed,
        ),
      ),
    );
  }
}
