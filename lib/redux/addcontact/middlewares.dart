import "dart:async";

import "package:moxxyv2/helpers.dart";
import "package:moxxyv2/models/roster.dart";
import "package:moxxyv2/models/conversation.dart";
import "package:moxxyv2/ui/pages/conversation/arguments.dart";
import "package:moxxyv2/redux/state.dart";
import "package:moxxyv2/redux/global/actions.dart";
import "package:moxxyv2/redux/addcontact/actions.dart";
import "package:moxxyv2/redux/conversation/actions.dart";
import "package:moxxyv2/redux/roster/actions.dart";
import "package:moxxyv2/repositories/roster.dart";
import "package:moxxyv2/repositories/database.dart";
import "package:moxxyv2/db/roster.dart" as db;

import "package:flutter/material.dart";
import "package:redux/redux.dart";
import "package:get_it/get_it.dart";
import "package:flutter_redux_navigation/flutter_redux_navigation.dart";
import "package:flutter_background_service/flutter_background_service.dart";

Future<void> addcontactMiddleware(Store<MoxxyState> store, action, NextDispatcher next) async {
  if (action is AddContactAction) {
    print("Adding ${action.jid} to roster");
    
    FlutterBackgroundService().sendData({
        "type": "AddToRosterAction",
        "jid": action.jid
    });
    store.dispatch(SetDoingWorkAction(state: true));
  } else if (action is AddToRosterDoneAction) {
    store.dispatch(SetDoingWorkAction(state: false));

    if (action.result == "success") {
      store.dispatch(NavigateToAction.pushNamedAndRemoveUntil(
          "/conversation",
          ModalRoute.withName("/conversations"),
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
