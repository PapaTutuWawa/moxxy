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
  final databaseRepo = GetIt.I.get<DatabaseRepository>();
  final connection = GetIt.I.get<XmppConnection>();
  if (action is ReceiveMessageAction) {
    final now = DateTime.now().millisecondsSinceEpoch;
    final bareJidString = action.from.toBare().toString();
    
    final message = await databaseRepo.addMessageFromData(
      action.body,
      now,
      bareJidString,
      bareJidString,
      false
    );

    final existantConversation = firstWhereOrNull(store.state.conversations, (Conversation c) => c.jid == bareJidString);
    if (existantConversation == null) {
      final conversation = await databaseRepo.addConversationFromData(
        action.from.local,
        action.body,
        "", // TODO
        bareJidString,
        1,
        now,
        [],
        true
      );

      databaseRepo.loadedConversations.add(bareJidString);
      store.dispatch(AddConversationAction(conversation: conversation));
    } else {
      print(store.state.openConversationJid);
      bool incrementUnreadCounter = store.state.openConversationJid == null || store.state.openConversationJid != existantConversation.jid;
      int unreadCounter = incrementUnreadCounter ? existantConversation.unreadCounter + 1 : existantConversation.unreadCounter;
      await databaseRepo.updateConversation(
        id: existantConversation.id,
        lastMessageBody: action.body,
        lastChangeTimestamp: now,
        unreadCounter: unreadCounter
      );
      store.dispatch(UpdateConversationAction(
          conversation: existantConversation.copyWith(
            lastMessageBody: action.body,
            lastChangeTimestamp: now,
            unreadCounter: unreadCounter
          )
      ));
    }

    store.dispatch(AddMessageAction(message: message));
  } else if (action is SendMessageAction) {
    final message = await databaseRepo.addMessageFromData(
      action.body,
      action.timestamp,
      connection.settings.jid.toString(),
      action.jid,
      true
    );
    connection.sendMessage(action.body, action.jid);

    final existantConversation = firstWhereOrNull(store.state.conversations, (Conversation c) => c.jid == action.jid);

    store.dispatch(AddMessageAction(message: message));
    store.dispatch(UpdateConversationAction(
      conversation: existantConversation!.copyWith(
        lastMessageBody: action.body
      )
    ));
  } else if (action is LoadMessagesAction) {
    GetIt.I.get<DatabaseRepository>().loadMessagesForJid(action.jid);
  }
  
  next(action);
}
