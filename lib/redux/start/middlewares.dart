import "package:moxxyv2/redux/state.dart";
import "package:moxxyv2/redux/start/actions.dart";
import "package:moxxyv2/redux/account/actions.dart";
import "package:moxxyv2/redux/account/state.dart";
import "package:moxxyv2/backend/account.dart";

import "package:redux/redux.dart";
import "package:flutter_redux_navigation/flutter_redux_navigation.dart";
import "package:get_it/get_it.dart";

void startMiddlewareAsync(Store<MoxxyState> store) async {
  final AccountState? account = await getAccountData();
  if (account != null) {
    store.dispatch(SetAccountAction(state: account));
    store.dispatch(NavigateToAction.replace("/conversations"));
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
