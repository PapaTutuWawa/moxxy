import "package:moxxyv2/ui/constants.dart";
import "package:moxxyv2/shared/commands.dart" as commands;
import "package:moxxyv2/ui/redux/state.dart";
import "package:moxxyv2/ui/redux/conversation/actions.dart";
import "package:moxxyv2/ui/pages/conversation/arguments.dart";

import "package:flutter/material.dart";
import "package:redux/redux.dart";
import "package:flutter_background_service/flutter_background_service.dart";
import "package:flutter_redux_navigation/flutter_redux_navigation.dart";

void conversationsMiddleware(Store<MoxxyState> store, action, NextDispatcher next) async {
  if (action is AddConversationFromUIAction) {
    final jid = action.jid;
    if (store.state.conversations.containsKey(jid)) {
      // Just go there
      FlutterBackgroundService().sendData(
        commands.LoadMessagesForJidAction(jid: jid).toJson()
      );

      store.dispatch(NavigateToAction.pushNamedAndRemoveUntil(
          conversationRoute,
          ModalRoute.withName(conversationsRoute),
          arguments: ConversationPageArguments(jid: jid)
        )
      );
    } else {
      FlutterBackgroundService().sendData(
        commands.AddConversationAction(
          jid: action.jid,
          title: action.title,
          avatarUrl: action.avatarUrl,
          lastMessageBody: action.lastMessageBody
        ).toJson()
      );
    }
  }

  next(action);
}
