import 'package:flutter/material.dart';

/// A class for adding a shadow to Containers which even works if the
/// Container is transparent.
///
/// NOTE: https://stackoverflow.com/a/55833281; Thank you kind stranger
class TransparentBoxShadow extends BoxShadow {
  const TransparentBoxShadow({
      required double blurRadius,
  }) : super(blurRadius: blurRadius);

  @override
  Paint toPaint() {
    final result = Paint()
      ..color = color
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma);

    return result;
  }
}

/// A widget to show a message that was sent within a chat or is about to be sent.
class SharedMediaContainer extends StatelessWidget {

  const SharedMediaContainer(this.child, { this.onTap, Key? key }) : super(key: key);
  final Widget? child;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: SizedBox(
        height: 75,
        width: 75,
        child: AspectRatio(
          aspectRatio: 1,
          child: child, 
        ),
      ),
    );
  }
}
