import 'dart:async';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/service/connectivity.dart';
import 'package:moxxyv2/service/notifications.dart';
import 'package:synchronized/synchronized.dart';

class ConnectivityWatcherService {
  /// Logger.
  final Logger _log = Logger('ConnectivityWatcherService');

  /// Timer counting how much time has passed since we were last connected.
  Timer? _timer;

  /// Lock for accessing _timer
  final Lock _lock = Lock();

  Future<void> initialize() async {
    GetIt.I.get<ConnectivityService>().stream.listen(_onConnectivityEvent);
  }

  Future<void> _onConnectivityEvent(ConnectivityEvent event) async {
    if (event.lost) {
      _log.finest('Network connection lost. Stopping timer');
      await _stopTimer();
    }
  }

  Future<void> _onTimerElapsed() async {
    await _stopTimer();
    await GetIt.I.get<NotificationsService>().showWarningNotification(
          'Moxxy',
          t.errors.connection.connectionTimeout,
        );
  }

  /// Stops the currently running timer, if there is one.
  Future<void> _stopTimer() async {
    await _lock.synchronized(() {
      _timer?.cancel();
      _timer = null;
    });
  }

  /// Starts the timer. If it is already running, it stops the currently running one before
  /// starting the new one.
  Future<void> _startTimer() async {
    await _stopTimer();
    _timer = Timer(const Duration(minutes: 30), _onTimerElapsed);
  }

  /// Called when the XMPP connection state changed
  Future<void> onConnectionStateChanged(
    XmppConnectionState before,
    XmppConnectionState current,
  ) async {
    if (before == XmppConnectionState.connected &&
        current != XmppConnectionState.connected) {
      // We somehow lost connection
      if (await GetIt.I.get<ConnectivityService>().hasConnection()) {
        _log.finest('Lost connection to server. Starting warning timer...');
        await _startTimer();
      } else {
        _log.finest(
          'Lost connection to server but no network connectivity available. Stopping warning timer...',
        );
        await _stopTimer();
      }
    } else if (current == XmppConnectionState.connected) {
      await _stopTimer();
    }
  }
}
