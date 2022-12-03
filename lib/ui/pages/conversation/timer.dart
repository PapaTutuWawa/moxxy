import 'dart:async';
import 'package:flutter/material.dart';
import 'package:moxxyv2/shared/helpers.dart';

String intToTimestring(int p) {
  if (p < 60) {
    return '0:${padInt(p)}';
  }

  final minutes = (p / 60).floor();
  final seconds = padInt(p - minutes * 60);
  return '$minutes:$seconds';
}

class TimerWidget extends StatefulWidget {
  const TimerWidget({ super.key });

  @override
  TimerWidgetState createState() => TimerWidgetState();
}

class TimerWidgetState extends State<TimerWidget> {
  late Timer _timer;
  int _seconds = 0;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        setState(() {
          _seconds++;
        });
      },
    );
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      intToTimestring(_seconds),
      style: const TextStyle(
        fontSize: 20,
      ),
    );
  }
}
