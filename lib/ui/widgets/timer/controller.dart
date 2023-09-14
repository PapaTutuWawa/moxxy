import 'package:flutter/foundation.dart';

class TimerController {
  ///
  final ValueNotifier<bool> runningNotifier = ValueNotifier<bool>(false);

  /// The running time in seconds.
  int _runtime = 0;
  int get runtime => _runtime;

  void reset() {
    _runtime = 0;
  }

  void tick() {
    _runtime += 1;
  }
}
