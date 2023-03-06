import 'package:decorated_icon/decorated_icon.dart';
import 'package:flutter/material.dart';

class PlayButton extends StatelessWidget {
  const PlayButton({
    this.size = 64.0,
    super.key,
  });
  final double size;

  @override
  Widget build(BuildContext context) {
    return Align(
      child: DecoratedIcon(
        Icons.play_arrow,
        shadows: const [BoxShadow(blurRadius: 16)],
        size: size,
      ),
    );
  }
}
