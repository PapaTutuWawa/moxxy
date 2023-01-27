import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';

class ConnectivityEvent {
  const ConnectivityEvent(this.regained, this.lost);
  final bool regained;
  final bool lost;
}

class ConnectivityService {
  /// The internal stream controller
  final StreamController<ConnectivityEvent> _controller = StreamController<ConnectivityEvent>.broadcast();

  /// The logger
  final Logger _log = Logger('ConnectivityService');

  /// Caches the current connectivity state
  late ConnectivityResult _connectivity;

  Stream<ConnectivityEvent> get stream => _controller.stream;
  
  @visibleForTesting
  void setConnectivity(ConnectivityResult result) {
    _log.warning('Internal connectivity state changed by request originating from outside ConnectivityService');
    _connectivity = result;
  }
  
  Future<void> initialize() async {
    final conn = Connectivity();
    _connectivity = await conn.checkConnectivity();

    conn.onConnectivityChanged.listen((ConnectivityResult result) {
      final regained = _connectivity == ConnectivityResult.none && result != ConnectivityResult.none;
      final lost = result == ConnectivityResult.none;
      _connectivity = result;

      _controller.add(
        ConnectivityEvent(
          regained,
          lost,
        ),
      );
    });
  }

  ConnectivityResult get currentState => _connectivity;

  Future<bool> hasConnection() async {
    return _connectivity != ConnectivityResult.none;
  }
}
