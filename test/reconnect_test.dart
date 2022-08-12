import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxyv2/service/connectivity.dart';
import 'package:moxxyv2/service/moxxmpp/reconnect.dart';
import 'package:test/test.dart';

import 'helpers/logging.dart';

void main() {
  initLogger();

  final service = ConnectivityService()
    ..setConnectivity(ConnectivityResult.wifi);
  GetIt.I.registerSingleton<ConnectivityService>(service);

  test('Test the network-connection-aware reconnection policy', () async {
    var performReconnectCalled = 0;
    var triggerConnectionLostCalled = false;
    final policy = MoxxyReconnectionPolicy(isTesting: true);
    policy.register(
      () async {
        // performReconnect
        performReconnectCalled++;
      },
      () {
        // triggerConnectionLost
        triggerConnectionLostCalled = true;
      }
    );

    // Test being connected and losing the connection
    policy.setShouldReconnect(true);
    await policy.onConnectivityChanged(false, true);
    expect(triggerConnectionLostCalled, true);
    expect(performReconnectCalled, 0);
    triggerConnectionLostCalled = false;
    performReconnectCalled = 0;
    
    // Test regaining the connection
    await policy.onConnectivityChanged(true, false);
    expect(triggerConnectionLostCalled, false);
    expect(policy.timer, isNot(equals(null)));
    // Trigger the reconnect
    await policy.onTimerElapsed();
    expect(performReconnectCalled, 1);
  });
}
