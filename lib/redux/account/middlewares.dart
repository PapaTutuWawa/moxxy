import "package:moxxyv2/redux/state.dart";
import "package:moxxyv2/redux/account/actions.dart";
import "package:moxxyv2/backend/account.dart";

import "package:redux/redux.dart";
import "package:flutter_redux_navigation/flutter_redux_navigation.dart";

void accountMiddleware(Store<MoxxyState> store, action, NextDispatcher next) {
  // TODO: SetJidAction should theorectically not be dispatched
  if (action is SetDisplayNameAction) {
    setAccountData(store.state.accountState.copyWith(displayName: action.displayName));
  } else if (action is SetAvatarAction) {
    setAccountData(store.state.accountState.copyWith(avatarUrl: action.avatarUrl));
  } else if (action is PerformLogoutAction) {
    removeAccountData();
    store.dispatch(NavigateToAction.replace("/intro"));
  }

  next(action);
}
