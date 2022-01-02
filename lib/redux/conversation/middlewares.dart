import "package:moxxyv2/ui/pages/conversation/arguments.dart";
import "package:moxxyv2/redux/state.dart";
import "package:moxxyv2/redux/messages/actions.dart";
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
  }
  
  next(action);
}
