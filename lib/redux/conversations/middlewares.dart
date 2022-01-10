import "package:moxxyv2/helpers.dart";
import "package:moxxyv2/redux/state.dart";
import "package:moxxyv2/redux/conversation/actions.dart";
import "package:moxxyv2/repositories/database.dart";
import "package:moxxyv2/models/conversation.dart";
import "package:moxxyv2/ui/pages/conversation/arguments.dart";

import "package:flutter/material.dart";
import "package:redux/redux.dart";
import "package:flutter_redux_navigation/flutter_redux_navigation.dart";
import "package:get_it/get_it.dart";

void conversationsMiddleware(Store<MoxxyState> store, action, NextDispatcher next) async {
  if (action is AddConversationFromUIAction) {
    // TODO: This should not depend on store.state. Use the cache
    // TODO: Move this into the repository
    final conversation = store.state.conversations[action.jid];
    final repo = GetIt.I.get<DatabaseRepository>();

    if (conversation == null) {
      final conversation = await GetIt.I.get<DatabaseRepository>().addConversationFromData(
        action.title,
        "",
        action.avatarUrl,
        action.jid,
        0,
        -1,
        [],
        true
      );
      store.dispatch(AddConversationAction(
          conversation: conversation
      ));
    } else {
      store.dispatch(UpdateConversationAction(
          conversation: conversation.copyWith(open: true)
      ));
    }

    store.dispatch(NavigateToAction.pushNamedAndRemoveUntil(
        "/conversation",
        ModalRoute.withName("/conversations"),
        arguments: ConversationPageArguments(jid: action.jid)
    ));
  } else if (action is CloseConversationAction) {
    GetIt.I.get<DatabaseRepository>().updateConversation(id: action.id, open: false);

    if (action.redirect) {
      store.dispatch(NavigateToAction.pushNamedAndRemoveUntil(
          "/conversations",
          (route) => false
      ));
    }
  } else if (action is UpdateConversationAction) {
    final c = action.conversation;
    GetIt.I.get<DatabaseRepository>().updateConversation(
      id: c.id,
      lastMessageBody: c.lastMessageBody,
      lastChangeTimestamp: c.lastChangeTimestamp,
      open: c.open,
      unreadCounter: c.unreadCounter
    );
  }

  next(action);
}
