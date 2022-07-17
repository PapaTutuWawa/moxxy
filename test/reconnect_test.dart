import "package:moxxyv2/service/connectivity.dart";
import "package:moxxyv2/service/moxxmpp/reconnect.dart";

import "package:get_it/get_it.dart";
import "package:test/test.dart";
import "package:connectivity_plus/connectivity_plus.dart";

import "helpers/logging.dart";

void main() {
  initLogger();

  final service = ConnectivityService()
    ..setConnectivity(ConnectivityResult.wifi);
  GetIt.I.registerSingleton<ConnectivityService>(service);

  test("Test the network-connection-aware reconnection policy", () {
    bool performReconnectCalled = false;
    bool triggerConnectionLostCalled = false;
    final policy = MoxxyReconnectionPolicy();
    policy.register(
      () {
        // performReconnect
        performReconnectCalled = true;
      },
      () {
        // triggerConnectionLost
        triggerConnectionLostCalled = true;
      }
    );

    // Test being connected and losing the connection
    policy.setShouldReconnect(true);
    policy.onConnectivityChanged(ConnectivityResult.none);
    expect(triggerConnectionLostCalled, true);
    expect(performReconnectCalled, false);
    triggerConnectionLostCalled = false;
    performReconnectCalled = false;
    
    // Test regaining the connection
    policy.onConnectivityChanged(ConnectivityResult.ethernet);
    expect(triggerConnectionLostCalled, false);
    // Handled by the [ExponentialBackoffReconnectionPolicy]
    //expect(performReconnectCalled, true);
  });
}
