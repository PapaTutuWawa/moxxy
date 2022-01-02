import "package:moxxyv2/helpers.dart";
import "package:moxxyv2/ui/pages/conversation/arguments.dart";
import "package:moxxyv2/models/conversation.dart";
import "package:moxxyv2/redux/state.dart";
import "package:moxxyv2/redux/messages/actions.dart";
import "package:moxxyv2/redux/conversations/actions.dart";
import "package:moxxyv2/redux/conversation/actions.dart";
import "package:moxxyv2/repositories/conversation.dart";

import "package:redux/redux.dart";
import "package:flutter_redux_navigation/flutter_redux_navigation.dart";
import "package:get_it/get_it.dart";

void conversationMiddleware(Store<MoxxyState> store, action, NextDispatcher next) async {
  if (action is NavigateToAction && action.type == NavigationType.shouldPush && action.name == "/conversation") {
    final args = action.arguments as ConversationPageArguments;
    if (GetIt.I.get<DatabaseRepository>().loadedConversations.indexOf(args.jid) == -1) {
      store.dispatch(LoadMessagesAction(jid: args.jid));
    }

    final conversation = firstWhereOrNull(store.state.conversations, (Conversation c) => c.jid == args.jid);
    if (conversation != null && conversation.unreadCounter > 0) {
      store.dispatch(UpdateConversationAction(
          conversation: conversation.copyWith(unreadCounter: 0)
      ));
    }

    store.dispatch(SetOpenConversationAction(jid: args.jid));
  }
  
  next(action);
}
