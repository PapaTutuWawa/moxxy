import "dart:async";
import "package:moxxyv2/redux/state.dart";
import "package:moxxyv2/redux/account/state.dart";
import "package:moxxyv2/redux/login/actions.dart";
import "package:moxxyv2/redux/account/actions.dart";
import "package:moxxyv2/backend/account.dart";

import "package:redux/redux.dart";
import "package:flutter_redux_navigation/flutter_redux_navigation.dart";

void loginMiddleware(Store<MoxxyState> store, action, NextDispatcher next) {
  if (action is PerformLoginAction) {
    // TODO: Remove
    Future.delayed(Duration(seconds: 3), () {
        store.dispatch(LoginSuccessfulAction(
            jid: action.jid,
            displayName: action.jid.split("@")[0],
            streamResumptionToken: ""
        ));
    });
  } else if (action is LoginSuccessfulAction) {
    store.dispatch(SetDisplayNameAction(displayName: action.displayName));
    store.dispatch(SetJidAction(jid: action.jid));

    setAccountData(AccountState(
        jid: action.jid,
        displayName: action.displayName,
        avatarUrl: "",
        streamResumptionToken: action.streamResumptionToken
    ));
    store.dispatch(NavigateToAction.replace("/conversations"));
  }
  
  next(action);
}
