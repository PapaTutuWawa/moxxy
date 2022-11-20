import 'package:decorated_icon/decorated_icon.dart';
import 'package:flutter/material.dart';

class CancelButton extends StatelessWidget {
  const CancelButton({
    required this.onPressed,
    super.key,
  });
  final void Function() onPressed;
  
  @override
  Widget build(BuildContext context) {
    return IconButton(
      color: Colors.white,
      icon: const DecoratedIcon(
        Icons.close,
        shadows: [BoxShadow(blurRadius: 8)],
      ),
      onPressed: onPressed,
    );
  }
}
