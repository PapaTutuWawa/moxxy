import "dart:math";

import "package:flutter/material.dart";

/// Based on https://docs.flutter.dev/cookbook/effects/typing-indicator

class _FlashingCircle extends StatelessWidget {
  final AnimationController controller;
  final Animation<double> animation;
  final Interval interval;
  final Color colorLight;
  final Color colorDark;

  _FlashingCircle(this.controller, this.animation, this.interval, this.colorLight, this.colorDark);

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final circleFlashPercent = interval.transform(controller.value,);
        final circleColorPercent = sin(pi * circleFlashPercent);

        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Color.lerp(
              colorLight,
              colorDark,
              circleColorPercent
            )
          )
        );
      }
    );
  }
}

class TypingIndicatorWidget extends StatefulWidget {
  final Color colorLight;
  final Color colorDark;

  const TypingIndicatorWidget(this.colorLight, this.colorDark);
  
  @override
  _TypingIndicatorWidget createState() => _TypingIndicatorWidget();
}

class _TypingIndicatorWidget extends State<TypingIndicatorWidget> with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  _TypingIndicatorWidget();
  
  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..forward()
      ..repeat();

    _animation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      reverseCurve: const Interval(0.0, 0.3, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: Row(
        children: [
          Padding(
            padding: EdgeInsets.all(2.0),
            child: _FlashingCircle(_controller, _animation, Interval(0.20, 0.7), widget.colorLight, widget.colorDark)
          ),
          Padding(
            padding: EdgeInsets.all(2.0),
            child: _FlashingCircle(_controller, _animation, Interval(0.40, 0.8), widget.colorLight, widget.colorDark)
          ),
          Padding(
            padding: EdgeInsets.all(2.0),
            child: _FlashingCircle(_controller, _animation, Interval(0.60, 0.9), widget.colorLight, widget.colorDark)
          ),
        ]
      )
    );
  }
}
