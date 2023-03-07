import 'package:flutter/material.dart';
import 'package:moxxyv2/ui/constants.dart';

class OverviewMenuItem extends StatelessWidget {
  const OverviewMenuItem({
    required this.icon,
    required this.text,
    required this.onPressed,
    super.key,
  });
  final IconData icon;
  final String text;
  final void Function() onPressed;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
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

class OverviewMenu extends StatelessWidget {
  const OverviewMenu(
    this._animation, {
    required this.highlight,
    required this.children,
    this.highlightMaterialBorder,
    this.rightBorder = true,
    this.left,
    this.right,
    this.materialColor,
    super.key,
  });
  final Animation<double> _animation;
  final Widget highlight;
  final List<Widget> children;
  final bool rightBorder;
  final double? left;
  final double? right;
  final BorderRadius? highlightMaterialBorder;
  final Color? materialColor;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Positioned(
              left: left,
              right: right,
              top: _animation.value,
              child: Material(
                borderRadius: highlightMaterialBorder,
                color: materialColor,
                child: highlight,
              ),
            );
          },
        ),
        Positioned(
          bottom: 50,
          right: rightBorder ? 8 : null,
          left: rightBorder ? null : 8,
          child: Row(
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.all(radiusLarge),
                child: Material(
                  child: IntrinsicHeight(
                    child: IntrinsicWidth(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: children,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
