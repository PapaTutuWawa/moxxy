import 'dart:async';
import 'dart:collection';
import 'package:synchronized/synchronized.dart';

/// A lock guarding a critical section that allows a certain number of parallel users
/// to be in the critical section at the same time.
class Semaphore {

  /// A semaphore that allows at max [_counter] users in the critical section.
  Semaphore(this._counter) : _queue = Queue(), _lock = Lock();
  final Lock _lock;
  final Queue<Completer<void>> _queue;
  int _counter;

  Future<void> aquire() async {
    Completer<void>? completer;
    await _lock.synchronized(() async {
      if (_counter <= 0) {
        completer = Completer<void>();
        _queue.add(completer!);
      } else {
        _counter--;
      }
    });

    if (completer != null) {
      await completer!.future;
    }
  }

  Future<void> release() async {
    await _lock.synchronized(() async {
      _counter++;
      if (_counter <= 0) {
        _queue.removeFirst().complete();
      }
    });
  }
}
