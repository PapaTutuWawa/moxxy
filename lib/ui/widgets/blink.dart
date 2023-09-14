import 'package:flutter/material.dart';

class BlinkingIcon extends StatefulWidget {
  const BlinkingIcon({
    required this.icon,
    required this.duration,
    required this.start,
    required this.end,
    this.size,
    this.delay = Duration.zero,
    super.key,
  });
  final IconData icon;
  final double? size;
  final Duration delay;
  final Duration duration;
  final Color start;
  final Color end;

  @override
  BlinkingIconState createState() => BlinkingIconState();
}

class BlinkingIconState extends State<BlinkingIcon>
    with TickerProviderStateMixin {
  late final AnimationController _recordingBlinkController;
  late final Animation<Color?> _recordingBlink;
  bool _blinkForward = true;

  @override
  void initState() {
    super.initState();

    _recordingBlinkController = AnimationController(
      duration: widget.duration,
      vsync: this,
    );

    _recordingBlink = ColorTween(
      begin: widget.start,
      end: widget.end,
    ).animate(_recordingBlinkController)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed ||
            status == AnimationStatus.dismissed) {
          if (_blinkForward) {
            _recordingBlinkController.reverse();
          } else {
            _recordingBlinkController.forward();
          }

          _blinkForward = !_blinkForward;
        }
      });

    _startBlinking();
  }

  Future<void> _startBlinking() async {
    await Future<void>.delayed(widget.delay);
    await _recordingBlinkController.forward();
  }

  @override
  void dispose() {
    _recordingBlinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _recordingBlink,
      builder: (_, __) {
        return Icon(
          widget.icon,
          color: _recordingBlink.value,
          size: widget.size,
        );
      },
    );
  }
}
