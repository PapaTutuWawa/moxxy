import "package:moxxyv2/ui/redux/state.dart";
import "package:moxxyv2/ui/redux/roster/actions.dart";

import "package:redux/redux.dart";
import "package:flutter_background_service/flutter_background_service.dart";

void rosterMiddleware(Store<MoxxyState> store, action, NextDispatcher next) {
  if (action is RemoveRosterItemUIAction) {
    FlutterBackgroundService().sendData({
        "type": "RemoveRosterItemAction",
        "jid": action.jid
    });
  }

  next(action);
}
