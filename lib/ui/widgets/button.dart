import 'package:flutter/material.dart';

class RoundedButton extends StatelessWidget {
  const RoundedButton({
    required this.child,
    required this.cornerRadius,
    required this.onTap,
    this.enabled = true,
    super.key,
  });
  final Widget child;
  final double cornerRadius;
  final void Function()? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(cornerRadius),
      child: Material(
        type: MaterialType.transparency,
        child: Ink(
          decoration: BoxDecoration(
            color: Theme.of(context).elevatedButtonTheme.style!.backgroundColor!.resolve(
              // ignore: prefer_collection_literals
              Set.from([
                  // ignore: prefer_if_elements_to_conditional_expressions
                  enabled ? MaterialState.selected : MaterialState.disabled,
              ]),
            ),
            borderRadius: BorderRadius.circular(cornerRadius),
          ),
          child: InkWell(
            onTap: enabled ? onTap : null,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Center(
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
