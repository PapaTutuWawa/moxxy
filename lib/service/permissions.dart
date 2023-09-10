import 'package:get_it/get_it.dart';
import 'package:moxxy_native/moxxy_native.dart';
import 'package:moxxyv2/service/xmpp_state.dart';

class PermissionsService {
  /// Access to the native APIs.
  final MoxxyPlatformApi _api = MoxxyPlatformApi();

  /// Returns true if the UI should request the notification permission. If not,
  /// returns false.
  /// If the permission should be requested, this method also sets the `XmppState`'s
  /// `askedNotificationPermission` to true.
  Future<bool> shouldRequestNotificationPermission() async {
    final xss = GetIt.I.get<XmppStateService>();
    final retValue = !(await xss.state).askedNotificationPermission;
    if (retValue) {
      await xss.modifyXmppState(
        (state) => state.copyWith(askedNotificationPermission: true),
      );
    }

    return retValue;
  }

  /// Returns true if the UI should request to not be battery-optimised. If not,
  /// returns false. Also returns false if the app is already ignoring battery optimisations.
  /// If the excemption should be requested, this method also sets the `XmppState`'s
  /// `askedBatteryOptimizationExcemption` to true.
  Future<bool> shouldRequestBatteryOptimisationExcemption() async {
    if (await _api.isIgnoringBatteryOptimizations()) {
      return false;
    }

    final xss = GetIt.I.get<XmppStateService>();
    final retValue = !(await xss.state).askedBatteryOptimizationExcemption;
    if (retValue) {
      await xss.modifyXmppState(
        (state) => state.copyWith(askedBatteryOptimizationExcemption: true),
      );
    }

    return retValue;
  }
}
