import "package:moxxyv2/redux/state.dart";
import "package:moxxyv2/redux/start/actions.dart";
import "package:moxxyv2/redux/account/actions.dart";
import "package:moxxyv2/redux/account/state.dart";
import "package:moxxyv2/backend/account.dart";
import "package:moxxyv2/repositories/roster.dart";
import "package:moxxyv2/repositories/xmpp.dart";

import "package:redux/redux.dart";
import "package:flutter_redux_navigation/flutter_redux_navigation.dart";
import "package:get_it/get_it.dart";

void startMiddlewareAsync(Store<MoxxyState> store) async {
  final AccountState? account = await getAccountData();
  final repo = GetIt.I.get<XmppRepository>();
  final settings = await repo.loadConnectionSettings();

  if (account != null && settings != null) {
    await GetIt.I.get<RosterRepository>().loadRosterFromDatabase();
    store.dispatch(SetAccountAction(state: account));
    store.dispatch(NavigateToAction.replace("/conversations"));
    repo.connect(settings, false);
  } else {
    store.dispatch(NavigateToAction.replace("/intro"));
  }
}

void startMiddleware(Store<MoxxyState> store, action, NextDispatcher next) {
  if (action is PerformPrestartAction) {
    startMiddlewareAsync(store);
  }
  
  next(action);
}
