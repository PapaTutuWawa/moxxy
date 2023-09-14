import 'package:flutter/material.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/widgets/chat/typing.dart';

/// A helper widget that displays a [TypingIndicatorWidget] in a stack, so that it can
/// be animated in and out of the bottom of the screen with a "sliding" animation.
class AnimatedTypingIndicator extends StatefulWidget {
  const AnimatedTypingIndicator({
    required this.visible,
    super.key,
  });

  /// If set to true, animate the typing indicator into view. If false, reverse the
  /// animation.
  final bool visible;

  @override
  AnimatedTypingIndicatorState createState() => AnimatedTypingIndicatorState();
}

class AnimatedTypingIndicatorState extends State<AnimatedTypingIndicator>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutCubic,
      ),
    );

    if (widget.visible) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  void didUpdateWidget(AnimatedTypingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.visible != oldWidget.visible) {
      if (widget.visible) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        if (_animation.value == 0) {
          return const SizedBox();
        }

        return Stack(
          children: [
            // Pad the stack to the desired height
            SizedBox(
              height: 40 * _animation.value,
            ),

            child!,
          ],
        );
      },
      child: const Positioned(
        top: 0,
        left: 8,
        child: SizedBox(
          height: 40,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: bubbleColorReceived,
              borderRadius: BorderRadius.all(radiusLarge),
            ),
            child: Padding(
              padding: EdgeInsets.all(8),
              child: TypingIndicatorWidget(Colors.black, Colors.white),
            ),
          ),
        ),
      ),
    );
  }
}
