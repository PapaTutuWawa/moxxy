import "package:flutter/material.dart";

class DownloadButton extends StatelessWidget {
  final void Function() onPressed;

  const DownloadButton({ required this.onPressed, Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Ink(
      decoration: const ShapeDecoration(
        color: Colors.black45,
        shape: CircleBorder()
      ),
      child: IconButton(
        icon: const Icon(Icons.download),
        iconSize: 64.0,
        color: Colors.white,
        onPressed: onPressed
      )
    );
  }
}
