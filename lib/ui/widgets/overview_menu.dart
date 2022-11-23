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
    return InkResponse(
      onTap: onPressed,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.only(
              top: 8,
              right: 8,
              bottom: 8,
            ),
            child: Icon(icon),
          ),
          Text(text),
        ],
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
      super.key,
    }
  );
  final Animation<double> _animation;
  final Widget highlight;
  final List<Widget> children;
  final bool rightBorder;
  final double? left;
  final double? right;
  final BorderRadius? highlightMaterialBorder;
  
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
              Material(
                borderRadius: const BorderRadius.all(radiusLarge),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: IntrinsicHeight(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: children,
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
