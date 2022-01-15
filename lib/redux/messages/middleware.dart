import "package:moxxyv2/redux/state.dart";
import "package:moxxyv2/redux/conversation/actions.dart";
import "package:moxxyv2/helpers.dart";

import "package:redux/redux.dart";
import "package:flutter_background_service/flutter_background_service.dart";

void messageMiddleware(Store<MoxxyState> store, action, NextDispatcher next) async {
  if (action is SendMessageAction) {
    FlutterBackgroundService().sendData({
        "type": "SendMessageAction",
        "body": action.body,
        "jid": action.jid
    });
  }
  
  next(action);
}
