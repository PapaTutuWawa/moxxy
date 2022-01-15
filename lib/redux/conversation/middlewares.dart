import "package:moxxyv2/helpers.dart";
import "package:moxxyv2/ui/pages/conversation/arguments.dart";
import "package:moxxyv2/models/conversation.dart";
import "package:moxxyv2/redux/state.dart";
import "package:moxxyv2/redux/messages/actions.dart";
import "package:moxxyv2/redux/conversation/actions.dart";
import "package:moxxyv2/repositories/database.dart";

import "package:redux/redux.dart";
import "package:flutter_redux_navigation/flutter_redux_navigation.dart";
import "package:get_it/get_it.dart";
import "package:flutter_background_service/flutter_background_service.dart";

void conversationMiddleware(Store<MoxxyState> store, action, NextDispatcher next) async {
  if (action is NavigateToAction && action.type == NavigationType.shouldPush && action.name == "/conversation") {
    final args = action.arguments as ConversationPageArguments;
    FlutterBackgroundService().sendData({
        "type": "SetCurrentlyOpenChatAction",
        "jid": args.jid
    });

    if (!store.state.messages.containsKey(args.jid)) {
      FlutterBackgroundService().sendData({
          "type": "LoadMessagesForJidAction",
          "jid": args.jid
      });
    }
  }
  
  next(action);
}
