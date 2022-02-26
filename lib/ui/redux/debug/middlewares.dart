import "package:moxxyv2/ui/redux/state.dart";
import "package:moxxyv2/ui/redux/debug/actions.dart";
import "package:moxxyv2/shared/commands.dart" as commands;

import "package:redux/redux.dart";
import "package:flutter_background_service/flutter_background_service.dart";

void debugMiddleware(Store<MoxxyState> store, action, NextDispatcher next) {
  if (action is DebugSetEnabledAction) {
    if (!action.preStart) {
      FlutterBackgroundService().sendData(
        commands.DebugSetEnabledAction(enabled: action.enabled).toJson()
      );
    }
  } else if (action is DebugSetIpAction) {
    FlutterBackgroundService().sendData(
      commands.DebugSetIpAction(ip: action.ip).toJson()
    );
  } else if (action is DebugSetPortAction) {
    FlutterBackgroundService().sendData(
      commands.DebugSetPortAction(port: action.port).toJson()
    );
  } else if (action is DebugSetPassphraseAction) {
    FlutterBackgroundService().sendData(
      commands.DebugSetPassphraseAction(passphrase: action.passphrase).toJson()
    );
  } 

  next(action);
}
