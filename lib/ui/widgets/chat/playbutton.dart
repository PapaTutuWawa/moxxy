import 'package:flutter/material.dart';

class PlayButton extends StatelessWidget {
  const PlayButton({
    this.size = 64.0,
    super.key,
  });
  final double size;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black45,
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(
          Icons.play_arrow,
          size: size,
        ),
      ),
    );
  }
}
