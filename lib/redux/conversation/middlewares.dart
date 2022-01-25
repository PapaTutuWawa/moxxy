import "package:moxxyv2/ui/constants.dart";
import "package:moxxyv2/ui/pages/conversation/arguments.dart";
import "package:moxxyv2/redux/state.dart";
import "package:moxxyv2/redux/conversation/actions.dart";

import "package:redux/redux.dart";
import "package:flutter_redux_navigation/flutter_redux_navigation.dart";
import "package:flutter_background_service/flutter_background_service.dart";

void conversationMiddleware(Store<MoxxyState> store, action, NextDispatcher next) async {
  if (action is NavigateToAction && action.type == NavigationType.shouldPush && action.name == conversationRoute) {
    final args = action.arguments as ConversationPageArguments;
    FlutterBackgroundService().sendData({
        "type": "SetCurrentlyOpenChatAction",
        "jid": args.jid
    });

    FlutterBackgroundService().sendData({
        "type": "LoadMessagesForJidAction",
        "jid": args.jid
    });
  } else if (action is SetOpenConversationAction) {
    FlutterBackgroundService().sendData({
        "type": "SetCurrentlyOpenChatAction",
        "jid": action.jid ?? ""
    });
  }
  
  next(action);
}
