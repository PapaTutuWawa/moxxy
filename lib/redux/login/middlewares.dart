import "dart:async";
import "package:moxxyv2/redux/state.dart";
import "package:moxxyv2/redux/account/state.dart";
import "package:moxxyv2/redux/login/actions.dart";
import "package:moxxyv2/redux/account/actions.dart";
import "package:moxxyv2/redux/global/actions.dart";
import "package:moxxyv2/backend/account.dart";
import "package:moxxyv2/xmpp/connection.dart";
import "package:moxxyv2/xmpp/settings.dart";
import "package:moxxyv2/xmpp/jid.dart";
import "package:moxxyv2/repositories/xmpp.dart";

import "package:redux/redux.dart";
import "package:flutter_redux_navigation/flutter_redux_navigation.dart";
import "package:get_it/get_it.dart";

Future<void> loginMiddleware(Store<MoxxyState> store, action, NextDispatcher next) async {
  if (action is PerformLoginAction) {
    store.dispatch(SetDoingWorkAction(state: true));
    GetIt.I.get<XmppRepository>().connect(ConnectionSettings(
        jid: BareJID.fromString(action.jid),
        password: action.password,
        useDirectTLS: true,
        allowPlainAuth: false,
        streamResumptionSettings: StreamResumptionSettings()
    ), true);
  } else if (action is LoginSuccessfulAction) {
    store.dispatch(SetDoingWorkAction(state: false));
    store.dispatch(SetDisplayNameAction(displayName: action.displayName));
    store.dispatch(SetJidAction(jid: action.jid));

    setAccountData(AccountState(
        jid: action.jid,
        displayName: action.displayName,
        avatarUrl: ""
    ));
    store.dispatch(NavigateToAction.replace("/conversations"));
  }
  
  next(action);
}
