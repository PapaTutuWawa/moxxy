import 'dart:io' show Platform;

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:moxxyv2/service/moxxmpp/reconnect.dart';
import 'package:moxxyv2/xmpp/connection.dart';

class ConnectivityService {

  ConnectivityService() : _log = Logger('ConnectivityService');
  final Logger _log;

  /// Caches the current connectivity state
  late ConnectivityResult _connectivity;

  @visibleForTesting
  void setConnectivity(ConnectivityResult result) {
    _log.warning('Internal connectivity state changed by request originating from outside ConnectivityService');
    _connectivity = result;
  }
  
  Future<void> initialize() async {
    final conn = Connectivity();
    _connectivity = await conn.checkConnectivity();

    // TODO(Unknown): At least on Android, the stream fires directly after listening although the
    //                network does not change. So just skip it.
    // See https://github.com/fluttercommunity/plus_plugins/issues/567
    final skipAmount = Platform.isAndroid ? 1 : 0;
    conn.onConnectivityChanged.skip(skipAmount).listen((ConnectivityResult result) {
      _connectivity = result;

      // Notify other services
      final policy = GetIt.I.get<XmppConnection>().reconnectionPolicy;
      (policy as MoxxyReconnectionPolicy).onConnectivityChanged(result);
    });
  }

  ConnectivityResult get currentState => _connectivity;
}
