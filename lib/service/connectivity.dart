import "dart:io" show Platform;

import "package:moxxyv2/service/moxxmpp/reconnect.dart";

import "package:logging/logging.dart";
import "package:connectivity_plus/connectivity_plus.dart";
import "package:get_it/get_it.dart";

class ConnectivityService {
  final Logger _log;

  /// Caches the current connectivity state
  late ConnectivityResult _connectivity;

  ConnectivityService() : _log = Logger("ConnectivityService");

  Future<void> initialize() async {
    final conn = Connectivity();
    _connectivity = await conn.checkConnectivity();

    // TODO: At least on Android, the stream fires directly after listening although the
    //       network does not change. So just skip it.
    // See https://github.com/fluttercommunity/plus_plugins/issues/567
    final skipAmount = Platform.isAndroid ? 1 : 0;
    conn.onConnectivityChanged.skip(skipAmount).listen((ConnectivityResult result) {
        _connectivity = result;

        // Notify other services
        GetIt.I.get<MoxxyReconnectionPolicy>().onConnectivityChanged(result);
    });
  }

  ConnectivityResult get currentState => _connectivity;
}
