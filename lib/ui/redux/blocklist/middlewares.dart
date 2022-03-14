import "package:moxxyv2/ui/redux/state.dart";
import "package:moxxyv2/ui/redux/blocklist/actions.dart";
import "package:moxxyv2/shared/commands.dart" as commands;

import "package:redux/redux.dart";
import "package:flutter_background_service/flutter_background_service.dart";

void blocklistMiddleware(Store<MoxxyState> store, action, NextDispatcher next) {
  if (action is BlockJidUIAction) {
    FlutterBackgroundService().sendData(
      commands.BlockCommand(jid: action.jid).toJson()
    );
  } else if (action is UnblockJidUIAction) {
    FlutterBackgroundService().sendData(
      commands.UnblockCommand(jid: action.jid).toJson()
    );
  } else if (action is UnblockAllUIAction) {
    FlutterBackgroundService().sendData(
      commands.UnblockAllCommand().toJson()
    );
  }

  next(action);
}
