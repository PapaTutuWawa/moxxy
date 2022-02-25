import "package:moxxyv2/shared/models/conversation.dart";
import "package:moxxyv2/shared/models/message.dart";
import "package:moxxyv2/shared/models/roster.dart";
import "package:moxxyv2/ui/constants.dart";
import "package:moxxyv2/ui/redux/state.dart";
import "package:moxxyv2/ui/redux/conversation/actions.dart";
import "package:moxxyv2/ui/redux/login/actions.dart";
import "package:moxxyv2/ui/redux/addcontact/actions.dart";
import "package:moxxyv2/ui/redux/roster/actions.dart";
import "package:moxxyv2/ui/redux/account/state.dart";
import "package:moxxyv2/ui/redux/account/actions.dart";
import "package:moxxyv2/ui/redux/debug/actions.dart";

import "package:get_it/get_it.dart";
import "package:flutter_background_service/flutter_background_service.dart";
import "package:redux/redux.dart";
import "package:flutter_redux_navigation/flutter_redux_navigation.dart";
import "package:logging/logging.dart";

/// Called whenever the background service sends data to the UI isolate.
void handleBackgroundServiceData(Map<String, dynamic>? data) {
  final store = GetIt.I.get<Store<MoxxyState>>();
  if (data == null) {
    GetIt.I.get<Logger>().warning("handleBackgroundServiceData: Received null");
    return;
  }

  switch (data["type"]) {
    case "PreStartResult": {
      if (data["state"] == "logged_in") {
        FlutterBackgroundService().sendData({
            "type": "LoadConversationsAction"
        });

        store.dispatch(SetAccountAction(
            state: AccountState(
              jid: data["jid"],
              displayName: data["displayName"],
              avatarUrl: data["avatarUrl"]
            )
        ));

        store.dispatch(NavigateToAction.replace(conversationsRoute));
      } else {
        store.dispatch(NavigateToAction.replace(loginRoute));
      }

      store.dispatch(DebugSetEnabledAction(data["debugEnabled"], true));
    }
    break;
    case "LoginSuccessfulEvent": {
      store.dispatch(
        LoginSuccessfulAction(
          jid: data["jid"]!,
          displayName: data["displayName"]!
        )
      );
    }
    break;
    case "ConversationCreatedEvent": {
      store.dispatch(AddConversationAction(
          conversation: Conversation.fromJson(data["conversation"]!)
        )
      );
    }
    break;
    case "ConversationUpdatedEvent": {
      store.dispatch(
        UpdateConversationAction(
          conversation: Conversation.fromJson(data["conversation"]!)
        )
      );
    }
    break;
    case "MessageReceivedEvent": {
      store.dispatch(
        AddMessageAction(
          message: Message.fromJson(data["message"]!)
        )
      );
    }
    break;
    case "MessageUpdatedEvent": {
      store.dispatch(
        UpdateMessageAction(
          message: Message.fromJson(data["message"]!)
        )
      );
    }
    break;
    case "RosterDiff": {
      store.dispatch(
        RosterDiffAction(
          newItems: List<RosterItem>.from(data["newItems"]!.map((i) => RosterItem.fromJson(i))),
          
          changedItems: List<RosterItem>.from(data["changedItems"]!.map((i) => RosterItem.fromJson(i))),

          removedItems: List<String>.from(data["removedItems"]!)
        )
      );
    }
    break;
    case "LoadConversationsResult": {
      final List<Conversation> tmp = List<Conversation>.from(data["conversations"]!.map((c) => Conversation.fromJson(c)));
      store.dispatch(AddMultipleConversationsAction(
          conversations: tmp
      ));
    }
    break;
    case "LoadMessagesForJidResult": {
      final List<Message> tmp = List<Message>.from(data["messages"]!.map((m) => Message.fromJson(m)));
      store.dispatch(
        AddMultipleMessagesAction(
          conversationJid: data["jid"]!,
          messages: tmp,
          replace: true
        )
      );
    }
    break;
    case "AddToRosterResult": {
      store.dispatch(
        AddToRosterDoneAction(
          result: data["result"]!,
          msg: data["msg"],
          jid: data["jid"]
        )
      );
    }
    break;
    case "MessageSendResult": {
      store.dispatch(
        AddMessageAction(
          message: Message.fromJson(data["message"]!)
        )
      );
    }
    break;
  }
}
