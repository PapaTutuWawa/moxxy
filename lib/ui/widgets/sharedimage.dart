import "package:moxxyv2/ui/constants.dart";

import "package:flutter/material.dart";

/// A class for adding a shadow to Containers which even works if the
/// Container is transparent.
///
/// NOTE: https://stackoverflow.com/a/55833281; Thank you kind stranger
class TransparentBoxShadow extends BoxShadow {
  const TransparentBoxShadow({
      required double blurRadius
  }) : super(blurRadius: blurRadius);

  @override
  Paint toPaint() {
    final Paint result = Paint()
      ..color = color
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, blurSigma);

    return result;
  }
}

/// A widget to show a message that was sent within a chat or is about to be sent.
class SharedMediaContainer extends StatelessWidget {
  final Widget? child;
  final ImageProvider? image;
  final bool showBorder;
  final bool drawShadow;
  final void Function()? onTap;

  const SharedMediaContainer({ this.child, this.image, this.onTap, this.showBorder = false, this.drawShadow = false, Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 75,
        width: 75,
        child: AspectRatio(
          aspectRatio: 1.0,
          child: Container(
            child: child,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: showBorder ? Border.all(
                // TODO: Make this border prettier
                width: 2.0,
                color: primaryColor
              ) : null,
              boxShadow: drawShadow ? [ const TransparentBoxShadow(blurRadius: 2.0) ] : [],
              image: image != null ? DecorationImage(
                fit: BoxFit.cover,
                image: image!
              ) : null
            )
          )
        )
      )
    );
  }
}
