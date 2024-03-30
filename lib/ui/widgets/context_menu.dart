import 'package:flutter/material.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/helpers.dart';

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
        padding: EdgeInsets.symmetric(
          horizontal: pxToLp(48),
          // NOTE: 96px / 2
          vertical: pxToLp(48),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: TextStyle(
                fontSize: ptToFontSize(32),
                fontWeight: FontWeight.normal,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
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

  /// Computes the height of the context menu, given the number of items.
  static double computeHeight(BuildContext context, int numberItems) {
    return 2 * pxToLp(24) +
        numberItems *
            (pxToLp(48) + MediaQuery.of(context).textScaler.scale(32));
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(radiusLarge),
      child: Material(
        color: Theme.of(context).colorScheme.surfaceVariant,
        child: Padding(
          padding: EdgeInsets.symmetric(
            // 72px - 48px (Padding)
            vertical: pxToLp(24),
          ),
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
      ),
    );
  }
}
