import 'package:flutter/material.dart';

class RoundedButton extends StatelessWidget {

  const RoundedButton({
      required this.color,
      required this.child,
      required this.cornerRadius,
      this.onTap,
      Key? key,
  }) : super(key: key);
  final Color color;
  final Widget child;
  final double cornerRadius;
  final void Function()? onTap;

  // TODO(Unknown): Make the colors gray if onTap == null
  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Ink(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(cornerRadius),
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
