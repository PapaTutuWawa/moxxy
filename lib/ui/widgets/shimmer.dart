import 'package:flutter/material.dart';

const shimmerHighlightColor = Colors.white;
const shimmerBaseColor = Color(0x4CFFFFFF);

/// A simple widget emulating Facebook's shimmer loading effect. Note that it must be
/// wrapped in a widget that forces the ShimmerWidget to a given size because it will
/// otherwise just collapse into itself, having no size.
class ShimmerWidget extends StatefulWidget {
  const ShimmerWidget({
    this.baseColor = shimmerBaseColor,
    this.highlightColor = shimmerHighlightColor,
    super.key,
  });
  final Color baseColor;
  final Color highlightColor;

  @override
  ShimmerState createState() => ShimmerState();
}

class ShimmerState extends State<ShimmerWidget>
    with SingleTickerProviderStateMixin {
  late Animation<Color?> _animation;
  late AnimationController _controller;
  bool forward = true;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    // NOTE: Values taken from here: https://github.com/facebook/shimmer-android/blob/main/shimmer/src/main/java/com/facebook/shimmer/Shimmer.java#L62
    _animation = ColorTween(
      begin: widget.baseColor,
      end: widget.highlightColor,
    ).animate(_controller)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed ||
            status == AnimationStatus.dismissed) {
          if (forward) {
            _controller.reverse();
          } else {
            _controller.forward();
          }

          forward = !forward;
        }
      });

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ColoredBox(
          color: _animation.value!,
        );
      },
    );
  }
}
