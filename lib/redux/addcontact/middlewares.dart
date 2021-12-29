import "dart:async";
import "package:moxxyv2/redux/state.dart";
import "package:moxxyv2/redux/global/actions.dart";
import "package:moxxyv2/redux/addcontact/actions.dart";
import "package:moxxyv2/repositories/roster.dart";
import "package:moxxyv2/redux/roster/actions.dart";
import "package:moxxyv2/db/roster.dart" as db;

import "package:redux/redux.dart";
import "package:get_it/get_it.dart";
import "package:flutter_redux_navigation/flutter_redux_navigation.dart";

void addcontactMiddleware(Store<MoxxyState> store, action, NextDispatcher next) {
  if (action is AddContactAction) {
    store.dispatch(SetDoingWorkAction(state: true));
    // TODO: Remove
    store.dispatch(AddRosterItemAction(
        jid: action.jid,
        title: action.jid.split("@")[0],
        avatarUrl: "",
        triggeredByDatabase: false
    ));
    Future.delayed(Duration(seconds: 3), () {
        // TODO: Trigger some action when done
        // TODO
        store.dispatch(SetDoingWorkAction(state: false));
        store.dispatch(NavigateToAction.replace("/conversations"));
    });
  }

  next(action);
}
