import 'package:flutter/material.dart';
import 'package:moxxyv2/ui/constants.dart';

/// A item in the context menu [ContextMenu].
class ContextMenuItem extends StatelessWidget {
  const ContextMenuItem({
    required this.icon,
    required this.text,
    required this.onPressed,
    super.key,
  });

  /// The icon to show on the left side.
  final IconData icon;

  /// The text of the menu item.
  final String text;

  /// Callback for when the item is pressed.
  final VoidCallback onPressed;

  /// The height of a single [ContextMenuItem].
  static int height = 48;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon),
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(text),
            ),
          ],
        ),
      ),
    );
  }
}

/// A context menu.
class ContextMenu extends StatelessWidget {
  const ContextMenu({
    required this.children,
    super.key,
  });

  /// A list of [ContextMenuItem]s to display.
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(radiusLarge),
      child: Material(
        child: IntrinsicHeight(
          child: IntrinsicWidth(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}
