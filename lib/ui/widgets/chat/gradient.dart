import 'package:flutter/material.dart';

/// A widget providing a gradient slowly fading from the bottom to the top.
/// Must be used inside a [Stack].
class BottomGradient extends StatelessWidget {
  const BottomGradient(this.radius, {super.key});
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        alignment: Alignment.bottomCenter,
        decoration: BoxDecoration(
          borderRadius: radius,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withAlpha(0), Colors.black12, Colors.black54],
          ),
        ),
      ),
    );
  }
}
