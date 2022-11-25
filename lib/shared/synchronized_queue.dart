import 'dart:async';
import 'dart:collection';
import 'package:synchronized/synchronized.dart';

/// The function of this class is essentially a queue, that processes itself as long as
/// _shouldQueue is false. If not, all added items are held until removeQueueLock is
/// called. After that point, all added items bypass the lock and get immediately passed
/// to the callback.
class SynchronizedQueue<T> {
  SynchronizedQueue(this._callback);
  final Future<void> Function(T) _callback;
  final Queue<T> _queue = Queue<T>();
  final Lock _lock = Lock();
  // If true, then events queue up
  bool _shouldQueue = true;

  Future<void> add(T item) async {
    if (!_shouldQueue) {
      unawaited(_callback(item));
      return;
    }

    await _lock.synchronized(() {
      if (!_shouldQueue) {
        unawaited(_callback(item));
        return;
      }

      _queue.addLast(item);
    });
  }

  Future<void> removeQueueLock() async {
    await _lock.synchronized(() async {
      while (_queue.isNotEmpty) {
        final item = _queue.removeFirst();
        await _callback(item);
      }

      _shouldQueue = false;
    });
  }
}
