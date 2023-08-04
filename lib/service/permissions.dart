import 'package:get_it/get_it.dart';
import 'package:moxxyv2/service/xmpp_state.dart';

class PermissionsService {
  /// Returns true if the UI should request the notification permission. If not,
  /// returns false.
  /// If the permission should be requested, this method also sets the `XmppState`'s
  /// `askedNotificationPermission` to true.
  Future<bool> shouldRequestNotificationPermission() async {
    final xss = GetIt.I.get<XmppStateService>();
    final retValue = !(await xss.getXmppState()).askedNotificationPermission;
    if (retValue) {
      await xss.modifyXmppState(
        (state) => state.copyWith(askedNotificationPermission: true),
      );
    }

    return retValue;
  }

  /// Returns true if the UI should request to not be battery-optimised. If not,
  /// returns false.
  /// If the excemption should be requested, this method also sets the `XmppState`'s
  /// `askedBatteryOptimizationExcemption` to true.
  Future<bool> shouldRequestBatteryOptimisationExcemption() async {
    final xss = GetIt.I.get<XmppStateService>();
    final retValue = !(await xss.getXmppState()).askedBatteryOptimizationExcemption;
    if (retValue) {
      await xss.modifyXmppState(
        (state) => state.copyWith(askedBatteryOptimizationExcemption: true),
      );
    }

    return retValue;  
  }
}
