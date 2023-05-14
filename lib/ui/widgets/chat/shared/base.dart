import 'package:flutter/material.dart';

/// A class for adding a shadow to Containers which even works if the
/// Container is transparent.
///
/// NOTE: https://stackoverflow.com/a/55833281; Thank you kind stranger
class TransparentBoxShadow extends BoxShadow {
  const TransparentBoxShadow({
    required super.blurRadius,
  });

  @override
  Paint toPaint() {
    final result = Paint()
      ..color = color
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma);

    return result;
  }
}

const sharedMediaContainerDimension = 75.0;

/// A widget to show a message that was sent within a chat or is about to be sent.
class SharedMediaContainer extends StatelessWidget {
  const SharedMediaContainer(
    this.child, {
    required this.color,
    this.onTap,
    this.size = sharedMediaContainerDimension,
    this.borderRadius = 10,
    super.key,
  });
  final double borderRadius;
  final Widget? child;
  final void Function()? onTap;
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final childWidget = SizedBox(
      height: size,
      width: size,
      child: AspectRatio(
        aspectRatio: 1,
        child: child,
      ),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: Material(
        color: color,
        child: onTap != null
            ? InkWell(
                onTap: onTap,
                child: childWidget,
              )
            : childWidget,
      ),
    );
  }
}
