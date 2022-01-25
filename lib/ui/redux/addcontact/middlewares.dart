import "dart:async";

import "package:moxxyv2/ui/constants.dart";
import "package:moxxyv2/ui/pages/conversation/arguments.dart";
import "package:moxxyv2/ui/redux/state.dart";
import "package:moxxyv2/ui/redux/global/actions.dart";
import "package:moxxyv2/ui/redux/addcontact/actions.dart";

import "package:flutter/material.dart";
import "package:redux/redux.dart";
import "package:flutter_redux_navigation/flutter_redux_navigation.dart";
import "package:flutter_background_service/flutter_background_service.dart";

Future<void> addcontactMiddleware(Store<MoxxyState> store, action, NextDispatcher next) async {
  if (action is AddContactAction) {
    FlutterBackgroundService().sendData({
        "type": "AddToRosterAction",
        "jid": action.jid
    });
    store.dispatch(SetDoingWorkAction(state: true));
  } else if (action is AddToRosterDoneAction) {
    store.dispatch(SetDoingWorkAction(state: false));

    if (action.result == "success") {
      store.dispatch(NavigateToAction.pushNamedAndRemoveUntil(
          conversationRoute,
          ModalRoute.withName(conversationsRoute),
          arguments: ConversationPageArguments(jid: action.jid!)
      ));
    } else if (action.result == "error") {
      store.dispatch(
        AddContactSetErrorLogin(
          errorText: action.msg!
        )
      );
      return;
    }
  }

  next(action);
}
