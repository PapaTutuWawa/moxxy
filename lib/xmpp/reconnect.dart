import "dart:async";
import "dart:math";

import "package:logging/logging.dart";
import "package:meta/meta.dart";

abstract class ReconnectionPolicy {
  /// Function provided by [XmppConnection] that allows the policy
  /// to perform a reconnection.
  void Function()? performReconnect;

  /// Called by [XmppConnection] to register the policy.
  void register(void Function() performReconnect) {
    this.performReconnect = performReconnect;

    reset();
  }
  
  /// In case the policy depends on some internal state, this state must be reset
  /// to an initial state when [reset] is called. In case timers run, they must be
  /// terminated.
  void reset();

  /// Called by the [XmppConnection] when the reconnection failed.
  void onFailure();

  /// Caled by the [XmppConnection] when the reconnection was successful.
  void onSuccess();
}

/// A simple reconnection strategy: Make the reconnection delays exponentially longer
/// for every failed attempt.
class ExponentialBackoffReconnectionPolicy extends ReconnectionPolicy {
  int _counter;
  Timer? _timer;
  Logger _log;

  ExponentialBackoffReconnectionPolicy()
  : _counter = 0,
    _log = Logger("ExponentialBackoffReconnectionPolicy");

  /// Called when the backoff expired
  void _onTimerElapsed() {
    performReconnect!();
  }
  
  @override
  void reset() {
    _log.finest("Resetting internal state");
    _counter = 0;

    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
    }
  }

  @override
  void onFailure() {
    _log.finest("Failure occured. Starting exponential backoff");
    _counter++;

    if (_timer != null) {
      _timer!.cancel();
    }

    _timer = Timer(Duration(seconds: pow(2, _counter).toInt()), _onTimerElapsed);
  }

  @override
  void onSuccess() {
    reset();
  }
}

/// A stub reconnection policy for tests
@visibleForTesting
class TestingReconnectionPolicy extends ReconnectionPolicy {
  @override
  void onSuccess() {}

  @override
  void onFailure() {}

  @override
  void reset() {}
}
