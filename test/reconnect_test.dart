import "package:moxxyv2/service/moxxmpp/reconnect.dart";

import "package:test/test.dart";
import "package:connectivity_plus/connectivity_plus.dart";

void main() {
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
