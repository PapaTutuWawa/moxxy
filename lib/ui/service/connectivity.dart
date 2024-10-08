import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class UIConnectivityService {
  /// The connectivity tracking object
  final _conn = Connectivity();

  /// The cached connection state.
  List<ConnectivityResult> _state = [ConnectivityResult.none];
  List<ConnectivityResult> get status => _state;

  /// The subscription to the event stream
  late StreamSubscription<List<ConnectivityResult>> _subscription;

  bool get hasConnection => !_state.contains(ConnectivityResult.none);

  /// Initializes the event stream and populates the cache.
  Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();
    _state = await _conn.checkConnectivity();
    _subscription = _conn.onConnectivityChanged.listen((result) {
      _state = result;
    });
  }

  /// Disposes of the event stream subscription.
  void dispose() {
    _subscription.cancel();
  }
}
