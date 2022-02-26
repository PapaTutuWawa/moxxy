import "package:moxxyv2/shared/commands.dart" as commands;
import "package:moxxyv2/ui/redux/state.dart";
import "package:moxxyv2/ui/redux/conversation/actions.dart";

import "package:redux/redux.dart";
import "package:flutter_background_service/flutter_background_service.dart";

void messageMiddleware(Store<MoxxyState> store, action, NextDispatcher next) async {
  if (action is SendMessageAction) {
    FlutterBackgroundService().sendData(
      commands.SendMessageAction(
        body: action.body,
        jid: action.jid
      ).toJson()
    );
  }
  
  next(action);
}
