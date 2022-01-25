import "dart:async";

import "package:moxxyv2/ui/constants.dart";
import "package:moxxyv2/redux/state.dart";
import "package:moxxyv2/redux/global/actions.dart";
import "package:moxxyv2/redux/registration/actions.dart";

import "package:redux/redux.dart";
import "package:flutter_redux_navigation/flutter_redux_navigation.dart";

void registrationMiddleware(Store<MoxxyState> store, action, NextDispatcher next) {
  if (action is PerformRegistrationAction) {
    store.dispatch(SetDoingWorkAction(state: true));
    // TODO: Remove
    Future.delayed(const Duration(seconds: 3), () {
        // TODO: Trigger some action when done
        store.dispatch(SetDoingWorkAction(state: false));
        store.dispatch(NavigateToAction.replace(postRegistrationRoute));
    });
  }

  next(action);
}
