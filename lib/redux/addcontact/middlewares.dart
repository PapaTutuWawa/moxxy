import "dart:async";
import "package:moxxyv2/redux/state.dart";
import "package:moxxyv2/redux/global/actions.dart";
import "package:moxxyv2/redux/addcontact/actions.dart";

import "package:redux/redux.dart";
import "package:flutter_redux_navigation/flutter_redux_navigation.dart";

void addcontactMiddleware(Store<MoxxyState> store, action, NextDispatcher next) {
  if (action is AddContactAction) {
    store.dispatch(SetDoingWorkAction(state: true));
    // TODO: Remove
    Future.delayed(Duration(seconds: 3), () {
        // TODO: Trigger some action when done
        // TODO
        store.dispatch(SetDoingWorkAction(state: false));
        store.dispatch(NavigateToAction.replace("/conversations"));
    });
  }

  next(action);
}
