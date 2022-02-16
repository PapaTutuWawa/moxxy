import "package:moxxyv2/ui/redux/state.dart";
import "package:moxxyv2/ui/redux/debug/actions.dart";

import "package:redux/redux.dart";
import "package:flutter_background_service/flutter_background_service.dart";

void debugMiddleware(Store<MoxxyState> store, action, NextDispatcher next) {
  if (action is DebugSetEnabledAction) {
    FlutterBackgroundService().sendData({
        "type": "DebugSetEnabledAction",
        "enabled": action.enabled
    });
  } else if (action is DebugSetIpAction) {
    FlutterBackgroundService().sendData({
        "type": "DebugSetIpAction",
        "ip": action.ip
    });
  } else if (action is DebugSetPortAction) {
    FlutterBackgroundService().sendData({
        "type": "DebugSetPortAction",
        "port": action.port
    });
  } else if (action is DebugSetPassphraseAction) {
    FlutterBackgroundService().sendData({
        "type": "DebugSetPassphraseAction",
        "passphrase": action.passphrase
    });
  } 

  next(action);
}
