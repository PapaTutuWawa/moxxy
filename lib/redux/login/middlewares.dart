import "dart:async";

import "package:moxxyv2/ui/constants.dart";
import "package:moxxyv2/redux/state.dart";
import "package:moxxyv2/redux/login/actions.dart";
import "package:moxxyv2/redux/account/actions.dart";
import "package:moxxyv2/redux/global/actions.dart";

import "package:redux/redux.dart";
import "package:flutter_redux_navigation/flutter_redux_navigation.dart";
import "package:flutter_background_service/flutter_background_service.dart";

Future<void> loginMiddleware(Store<MoxxyState> store, action, NextDispatcher next) async {
  if (action is PerformLoginAction) {
    store.dispatch(SetDoingWorkAction(state: true));
    FlutterBackgroundService().sendData({
        "type": "PerformLoginAction",
        "jid": action.jid,
        "password": action.password,
        "useDirectTLS": true,
        "allowPlainAuth": false
    });
  } else if (action is LoginSuccessfulAction) {
    store.dispatch(SetDoingWorkAction(state: false));
    store.dispatch(SetDisplayNameAction(displayName: action.displayName));
    store.dispatch(SetJidAction(jid: action.jid));
    store.dispatch(NavigateToAction.replace(conversationsRoute));
  } else if (action is LoginFailedAction) {
    store.dispatch(SetDoingWorkAction(state: false));
  }
  
  next(action);
}
