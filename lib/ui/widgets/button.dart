import "package:flutter/material.dart";

class RoundedButton extends StatelessWidget {
  final Color color;
  final Widget child;
  final double cornerRadius;
  final void Function() onTap;

  const RoundedButton({
      required this.color,
      required this.child,
      required this.cornerRadius,
      required this.onTap,
      Key? key
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Ink(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(cornerRadius)
        ),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: child
            )
          )
        )
      )
    );
  }
}
