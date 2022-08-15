import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:moxxyv2/service/connectivity.dart';
import 'package:moxxyv2/service/notifications.dart';
import 'package:moxxyv2/xmpp/connection.dart';

class ConnectivityWatcherService {

  ConnectivityWatcherService() : _log = Logger('ConnectivityWatcherService');
  final Logger _log;

  // Timer counting how much time has passed since we were last connected
  Timer? _timer;

  Future<void> _onTimerElapsed() async {
    await GetIt.I.get<NotificationsService>().showWarningNotification(
      'Moxxy',
      'Could not connect to server',
    );
    _stopTimer();
  }

  /// Stops the currently running timer, if there is one.
  void _stopTimer() {
    if (_timer != null) {
      _timer!.cancel();
      _timer = null;
    }
  }
  
  /// Starts the timer. If it is already running, it stops the currently running one before
  /// starting the new one.
  void _startTimer() {
    _stopTimer();
    _timer = Timer(const Duration(minutes: 30), _onTimerElapsed);
  }
  
  /// Called when the XMPP connection state changed
  Future<void> onConnectionStateChanged(XmppConnectionState before, XmppConnectionState current) async {
    if (before == XmppConnectionState.connected && current != XmppConnectionState.connected) {
      // We somehow lost connection
      if (GetIt.I.get<ConnectivityService>().currentState != ConnectivityResult.none) {
        _log.finest('Lost connection to server. Starting warning timer...');
        _startTimer();
      } else {
        _log.finest('Lost connection to server but no network connectivity available. Stopping warning timer...');
        _stopTimer();
      }
    } else if (current == XmppConnectionState.connected) {
      _stopTimer();
    }
  }
}
