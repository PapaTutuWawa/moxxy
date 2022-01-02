import "package:moxxyv2/redux/state.dart";
import "package:moxxyv2/redux/conversations/actions.dart";
import "package:moxxyv2/redux/conversation/actions.dart";
import "package:moxxyv2/repositories/conversation.dart";
import "package:moxxyv2/models/conversation.dart";
import "package:moxxyv2/models/message.dart";
import "package:moxxyv2/redux/messages/actions.dart";
import "package:moxxyv2/xmpp/connection.dart";
import "package:moxxyv2/helpers.dart";

import "package:redux/redux.dart";
import "package:flutter_redux_navigation/flutter_redux_navigation.dart";
import "package:get_it/get_it.dart";

void messageMiddleware(Store<MoxxyState> store, action, NextDispatcher next) async {
  final repo = GetIt.I.get<DatabaseRepository>();
  if (action is ReceiveMessageAction) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final bareJidString = action.from.toBare().toString();
    
    final message = await repo.addMessageFromData(
      action.body,
      now,
      bareJidString,
      bareJidString,
      false
    );

    final existantConversation = firstWhereOrNull(store.state.conversations, (Conversation c) => c.jid == bareJidString);
    if (existantConversation == null) {
      final conversation = await repo.addConversationFromData(
        action.from.local,
        action.body,
        "", // TODO
        bareJidString,
        1,
        now,
        [],
        true
      );

      repo.loadedConversations.add(bareJidString);
      store.dispatch(AddConversationAction(conversation: conversation));
    } else {
      await repo.updateConversation(
        id: existantConversation.id,
        lastMessageBody: action.body,
        lastChangeTimestamp: now,
        unreadCounter: existantConversation.unreadCounter + 1
      );
      store.dispatch(UpdateConversationAction(
          conversation: existantConversation.copyWith(
            lastMessageBody: action.body,
            lastChangeTimestamp: now,
            unreadCounter: existantConversation.unreadCounter + 1
          )
      ));
    }

    store.dispatch(AddMessageAction(message: message));
  } else if (action is SendMessageAction) {
    final message = await repo.addMessageFromData(
      action.body,
      action.timestamp,
      "", // TODO
      action.jid,
      true
    );
    GetIt.I.get<XmppConnection>().sendMessage(action.body, action.jid);

    store.dispatch(AddMessageAction(message: message));
  } else if (action is LoadMessagesAction) {
    GetIt.I.get<DatabaseRepository>().loadMessagesForJid(action.jid);
  }
  
  next(action);
}
