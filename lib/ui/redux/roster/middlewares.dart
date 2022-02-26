import "package:moxxyv2/shared/commands.dart" as commands;
import "package:moxxyv2/ui/redux/state.dart";
import "package:moxxyv2/ui/redux/roster/actions.dart";

import "package:redux/redux.dart";
import "package:flutter_background_service/flutter_background_service.dart";

void rosterMiddleware(Store<MoxxyState> store, action, NextDispatcher next) {
  if (action is RemoveRosterItemUIAction) {
    FlutterBackgroundService().sendData(
      commands.RemoveRosterItemAction(jid: action.jid).toJson()
    );
  }

  next(action);
}
