import "dart:async";

import "package:moxxyv2/helpers.dart";
import "package:moxxyv2/models/roster.dart";
import "package:moxxyv2/models/conversation.dart";
import "package:moxxyv2/ui/pages/conversation/arguments.dart";
import "package:moxxyv2/redux/state.dart";
import "package:moxxyv2/redux/global/actions.dart";
import "package:moxxyv2/redux/addcontact/actions.dart";
import "package:moxxyv2/repositories/roster.dart";
import "package:moxxyv2/repositories/conversation.dart";
import "package:moxxyv2/redux/roster/actions.dart";
import "package:moxxyv2/redux/conversations/actions.dart";
import "package:moxxyv2/db/roster.dart" as db;

import "package:flutter/material.dart";
import "package:redux/redux.dart";
import "package:get_it/get_it.dart";
import "package:flutter_redux_navigation/flutter_redux_navigation.dart";

Future<void> addcontactMiddleware(Store<MoxxyState> store, action, NextDispatcher next) async {
  if (action is AddContactAction) {
    print("Adding ${action.jid} to roster");
    final rosterRepo = GetIt.I.get<RosterRepository>();
    final databaseRepo = GetIt.I.get<DatabaseRepository>();

    store.dispatch(SetDoingWorkAction(state: true));
    if (firstWhereOrNull(store.state.roster, (RosterItem item) => item.jid == action.jid) != null) {
      // TODO: Display a message
      print("Already in roster");
      store.dispatch(SetDoingWorkAction(state: false));

      return;
    } else {
      final item = await rosterRepo.addToRoster("", action.jid, action.jid.split("@")[0]);
      store.dispatch(AddRosterItemAction(item: item));
    }

    final conversation = firstWhereOrNull(store.state.conversations, (Conversation c) => c.jid == action.jid);
    if (conversation == null) {
      final c = await databaseRepo.addConversationFromData(
        action.jid.split("@")[0],
        "",
        "",
        action.jid,
        0,
        -1,
        [],
        true
      );
      store.dispatch(AddConversationAction(conversation: c));
    } else {
      await databaseRepo.updateConversation(id: conversation.id, open: true);
      store.dispatch(UpdateConversationAction(
          conversation: conversation.copyWith(
            open: true
          )
      ));
    }

    store.dispatch(SetDoingWorkAction(state: false));
    store.dispatch(NavigateToAction.pushNamedAndRemoveUntil(
        "/conversation",
        ModalRoute.withName("/conversations"),
        arguments: ConversationPageArguments(jid: action.jid)
    ));
  }

  next(action);
}
