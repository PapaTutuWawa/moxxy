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
    // No timer when regaining connectivity
    expect(policy.timer, null);
    await Future.delayed(const Duration(seconds: 2));
    expect(performReconnectCalled, 1);

    // It was a success
    await policy.onSuccess();

    // Simulate a failure
    triggerConnectionLostCalled = false;
    print('--- Triggering a failure');
    await policy.onFailure();
    expect(triggerConnectionLostCalled, false);
    expect(performReconnectCalled, 1);
    expect(policy.timer, isNot(equals(null)));
  });

  group('Edge cases', () {
    test('Test having losing the connection while reconnecting', () async {
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

      // Fail
      policy.setShouldReconnect(true);
      await policy.onFailure();
      await policy.onTimerElapsed();
      expect(performReconnectCalled, 1);

      // Connection tries to reconnect and fails again
      await policy.onConnectivityChanged(false, true);

      // Connection comes again
      await policy.onConnectivityChanged(true, false);
      expect(performReconnectCalled, 2);
    });
  });
}
