import "package:moxxyv2/xmpp/reconnect.dart";
import "package:moxxyv2/service/connectivity.dart";

import "package:logging/logging.dart";
import "package:connectivity_plus/connectivity_plus.dart";
import "package:get_it/get_it.dart";

/// This class implements a reconnection policy that is a connectivity aware exponential
/// backoff. This means that we perform the exponential backoff only as long as we are
/// connected. Otherwise, we idle until we have a connection again.
// TODO: Maybe add locks to prevent a race condition between the network state and a
//       failure.
class MoxxyReconnectionPolicy extends ExponentialBackoffReconnectionPolicy {
  bool _failureQueued;
  Logger _log;

  MoxxyReconnectionPolicy()
  : _failureQueued = false,
    _log = Logger("MoxxyReconnectionPolicy"),
    super();

  /// To be called when the conectivity changes
  void onConnectivityChanged(ConnectivityResult result) {
    // Do nothing if we're not supposed to reconnect
    if (!shouldReconnect) {
      _log.finest("Connectivity changed but not attempting reconnection as shouldReconnect is false");
      return;
    }
    
    if (result != ConnectivityResult.none && _failureQueued) {
      _log.finest("Failure queued and connection available. Attemping reconnection...");
      _failureQueued = false;
      super.onFailure();
    } else if (result == ConnectivityResult.none) {
      _log.finest("Connection lost and no connection available. Queuing failure.");
      triggerConnectionLost!();
      onFailure();
    }
  }

  @override
  void onFailure() {
    final state = GetIt.I.get<ConnectivityService>().currentState;
    if (state != ConnectivityResult.none) {
      _log.finest("Reconnection failed and connection available. Attempting again after backoff...");
      super.onFailure();
    } else {
      _log.finest("Reconnection failed and no connection available. Queuing reconnection attempt...");
      _failureQueued = true;
    }
  }
}
