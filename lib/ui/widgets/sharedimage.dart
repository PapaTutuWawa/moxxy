import 'package:flutter/material.dart';
import 'package:moxxyv2/ui/constants.dart';

/*
 * A class for adding a shadow to Containers which even works if the
 * Container is transparent.
 *
 * NOTE: https://stackoverflow.com/a/55833281; Thank you kind stranger
 */
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

/*
 * A widget to show a message that was sent within a chat or is about to be sent
 */
class SharedMediaContainer extends StatelessWidget {
  Widget? child;
  ImageProvider? image;
  bool showBorder;
  bool drawShadow;
  void Function()? onTap;

  SharedMediaContainer({ this.child, this.image, this.onTap, this.showBorder = false, this.drawShadow = false });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: this.onTap,
      child: Container(
        height: 75,
        width: 75,
        child: AspectRatio(
          aspectRatio: 1.0,
          child: Container(
            child: this.child ?? null,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: this.showBorder ? Border.all(
                // TODO: Make this border prettier
                width: 2.0,
                color: PRIMARY_COLOR
              ) : null,
              boxShadow: this.drawShadow ? [ TransparentBoxShadow(blurRadius: 2.0) ] : [],
              image: this.image != null ? DecorationImage(
                fit: BoxFit.cover,
                image: this.image!
              ) : null
            )
          )
        )
      )
    );
  }
}
