import "dart:async";
import "dart:math";

import "package:logging/logging.dart";
import "package:meta/meta.dart";

abstract class ReconnectionPolicy {
  /// Function provided by [XmppConnection] that allows the policy
  /// to perform a reconnection.
  void Function()? performReconnect;
  /// Function provided by [XmppConnection] that allows the policy
  /// to say that we lost the connection.
  void Function()? triggerConnectionLost;
  /// Indicate if should try to reconnect.
  bool _shouldAttemptReconnection;

  ReconnectionPolicy() : _shouldAttemptReconnection = false;
  
  /// Called by [XmppConnection] to register the policy.
  void register(void Function() performReconnect, void Function() triggerConnectionLost) {
    this.performReconnect = performReconnect;
    this.triggerConnectionLost = triggerConnectionLost;

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

  bool get shouldReconnect => _shouldAttemptReconnection;

  /// Set whether a reconnection attempt should be made.
  void setShouldReconnect(bool value) {
    _shouldAttemptReconnection = value;
  }
}

/// A simple reconnection strategy: Make the reconnection delays exponentially longer
/// for every failed attempt.
class ExponentialBackoffReconnectionPolicy extends ReconnectionPolicy {
  int _counter;
  Timer? _timer;
  Logger _log;

  ExponentialBackoffReconnectionPolicy()
  : _counter = 0,
    _log = Logger("ExponentialBackoffReconnectionPolicy"),
    super();

  /// Called when the backoff expired
  void _onTimerElapsed() {
    if (shouldReconnect) {
      performReconnect!();
    }
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
  TestingReconnectionPolicy() : super();

  @override
  void onSuccess() {}

  @override
  void onFailure() {}

  @override
  void reset() {}
}
