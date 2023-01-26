import 'dart:async';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxyv2/service/connectivity.dart';
import 'package:synchronized/synchronized.dart';

class MoxxyConnectivityManager extends ConnectivityManager {
  MoxxyConnectivityManager() : super() {
    GetIt.I.get<ConnectivityService>().stream.listen(_onConnectivityChanged);
  }

  final Logger _log = Logger('MoxxyConnectivityManager');
  
  Completer<void>? _completer;

  final Lock _completerLock = Lock();

  Future<void> initialize() async {
    await _completerLock.synchronized(() async {
      final result = await GetIt.I.get<ConnectivityService>().hasConnection();
      if (!result) {
        _log.finest('No network connection at initialization: Creating completer');
        _completer = Completer<void>();
      }
    });
  }
  
  Future<void> _onConnectivityChanged(ConnectivityEvent event) async {
    if (event.regained) {
      await _completerLock.synchronized(() {
        _log.finest('Network regained. _completer != null: ${_completer != null}');
        _completer?.complete();
        _completer = null;
      });
    } else if (event.lost) {
      await _completerLock.synchronized(() {
        _log.finest('Network connection lost. Creating completer');
        _completer ??= Completer<void>();
      });
    }
  }
  
  @override
  Future<bool> hasConnection() async {
    return GetIt.I.get<ConnectivityService>().hasConnection();
  }

  @override
  Future<void> waitForConnection() async {
    final c = await _completerLock.synchronized(() => _completer);
    if (c != null) {
      _log.finest('waitForConnection: Completer non-null. Waiting.');
      await c.future;
    }
  }
}
