import 'dart:async';
import 'dart:math';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxyv2/service/connectivity.dart';
import 'package:synchronized/synchronized.dart';

/// This class implements a reconnection policy that is connectivity aware with a random
/// backoff. This means that we perform the random backoff only as long as we are
/// connected. Otherwise, we idle until we have a connection again.
class MoxxyReconnectionPolicy extends ReconnectionPolicy {

  MoxxyReconnectionPolicy({ bool isTesting = false })
  : _isTesting = isTesting,
    _timerLock = Lock(),
    _log = Logger('MoxxyReconnectionPolicy'),
    super();
  final Logger _log;

  /// The backoff timer
  @visibleForTesting
  Timer? timer;
  final Lock _timerLock;

  /// Just for testing purposes
  final bool _isTesting;
  
  /// To be called when the conectivity changes
  Future<void> onConnectivityChanged(bool regained, bool lost) async {
    // Do nothing if we should not reconnect
    if (!shouldReconnect && regained) {
      _log.finest('Connectivity changed but not attempting reconnection as shouldReconnect is false');
      return;
    }

    if (lost) {
      // We just lost network connectivity
      _log.finest('Lost network connectivity. Queueing failure...');

      // Cancel the timer if it was running
      await _stopTimer();
      await setIsReconnecting(false);
      triggerConnectionLost!();
    } else if (regained && shouldReconnect) {
      // We should reconnect
      _log.finest('Network regained. Attempting reconnection...');
      await _attemptReconnection(true);
    }
  }

  @override
  Future<void> reset() async {
    await _stopTimer();
    await setIsReconnecting(false);
  }

  Future<void> _stopTimer() async {
    await _timerLock.synchronized(() {
      if (timer != null) {
        timer!.cancel();
        timer = null;
        _log.finest('Destroying timer');
      }
    });
  }
  
  @visibleForTesting
  Future<void> onTimerElapsed() async {
    await _stopTimer();

    _log.finest('Performing reconnect');
    await performReconnect!();
  }

  Future<void> _attemptReconnection(bool immediately) async {
    if (await testAndSetIsReconnecting()) {
      // Attempt reconnecting
      final seconds = _isTesting ? 9999 : Random().nextInt(15);
      await _stopTimer();
      if (immediately) {
        _log.finest('Immediately attempting reconnection...');
        await onTimerElapsed();
      } else {
        _log.finest('Started backoff timer with ${seconds}s backoff');
        await _timerLock.synchronized(() {
          timer = Timer(Duration(seconds: seconds), onTimerElapsed);
        }); 
      }
    } else {
      _log.severe('_attemptReconnection called while reconnect is running!');
    }
  }
  
  @override
  Future<void> onFailure() async {
    final state = GetIt.I.get<ConnectivityService>().currentState;

    if (state != ConnectivityResult.none) {
      await _attemptReconnection(false);
    } else {
      _log.fine('Failure occurred while no network connection is available. Waiting for connection...');
    }
  }

  @override
  Future<void> onSuccess() async {
    await reset();
  }
}
