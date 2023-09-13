import 'dart:async';
import 'package:flutter/material.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/ui/widgets/timer/controller.dart';

String intToTimestring(int p) {
  if (p < 60) {
    return '0:${padInt(p)}';
  }

  final minutes = (p / 60).floor();
  final seconds = padInt(p - minutes * 60);
  return '$minutes:$seconds';
}

class TimerWidget extends StatefulWidget {
  const TimerWidget({
    required this.controller,
    super.key,
  });

  final TimerController controller;

  @override
  TimerWidgetState createState() => TimerWidgetState();
}

class TimerWidgetState extends State<TimerWidget> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    widget.controller.runningNotifier.addListener(_onRunningChanged);
    if (widget.controller.runningNotifier.value) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _stopTimer();
    widget.controller.runningNotifier.removeListener(_onRunningChanged);

    super.dispose();
  }

  void _startTimer() {
    _stopTimer();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        setState(() {
          widget.controller.tick();
        });
      },
    );
  }

  void _stopTimer() {
    _timer?.cancel();
  }

  void _onRunningChanged() {
    if (widget.controller.runningNotifier.value) {
      _startTimer();
    } else {
      _stopTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      intToTimestring(widget.controller.runtime),
      style: const TextStyle(
        fontSize: 20,
      ),
    );
  }
}
