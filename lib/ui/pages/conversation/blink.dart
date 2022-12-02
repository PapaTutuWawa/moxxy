import 'package:flutter/material.dart';

class BlinkingMicrophoneIcon extends StatefulWidget {
  const BlinkingMicrophoneIcon({ super.key });

  @override
  BlinkingMicrophoneIconState createState() => BlinkingMicrophoneIconState();
}

class BlinkingMicrophoneIconState extends State<BlinkingMicrophoneIcon> with TickerProviderStateMixin {
  late final AnimationController _recordingBlinkController;
  late final Animation<Color?> _recordingBlink;
  bool _blinkForward = true;

  @override
  void initState() {
    super.initState();

     _recordingBlinkController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _recordingBlink = ColorTween(
      begin: Colors.white,
      end: Colors.red.shade600,
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

    _recordingBlinkController.forward();
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
          Icons.mic,
          color: _recordingBlink.value,
        );
      },
    );
  }
}
