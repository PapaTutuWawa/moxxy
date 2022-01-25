import "package:moxxyv2/models/conversation.dart";
import "package:moxxyv2/models/message.dart";
import "package:moxxyv2/models/roster.dart";
import "package:moxxyv2/ui/constants.dart";
import "package:moxxyv2/ui/redux/state.dart";
import "package:moxxyv2/ui/redux/conversation/actions.dart";
import "package:moxxyv2/ui/redux/login/actions.dart";
import "package:moxxyv2/ui/redux/addcontact/actions.dart";
import "package:moxxyv2/ui/redux/roster/actions.dart";

import "package:get_it/get_it.dart";
import "package:flutter_background_service/flutter_background_service.dart";
import "package:redux/redux.dart";
import "package:flutter_redux_navigation/flutter_redux_navigation.dart";

/// Called whenever the background service sends data to the UI isolate.
void handleBackgroundServiceData(Map<String, dynamic>? data) {
  final store = GetIt.I.get<Store<MoxxyState>>();
  if (data!["type"]! != "__LOG__") {
    // TODO: Use logging function and only print on when debugging
    // ignore: avoid_print
    print("GOT: " + data.toString());
  }

  switch (data["type"]) {
    case "PreStartResult": {
      if (data["state"] == "logged_in") {
        FlutterBackgroundService().sendData({
            "type": "LoadConversationsAction"
        });
        /* TODO: Move this into the XmppRepository
        FlutterBackgroundService().sendData({
          "type": "GetAccountStateAction"
        });
        */

        store.dispatch(NavigateToAction.replace(conversationsRoute));
      } else {
        store.dispatch(NavigateToAction.replace(loginRoute));
      }
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
    case "LoadRosterItemsResult": {
      final List<RosterItem> tmp = List<RosterItem>.from(data["items"]!.map((i) => RosterItem.fromJson(i)));
      store.dispatch(
        AddMultipleRosterItemsAction(
          items: tmp
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
    case "RosterItemModifiedEvent": {
      store.dispatch(
        ModifyRosterItemAction(
          item: RosterItem.fromJson(data["item"]!)
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
    case "__LOG__": {
      // TODO: Use logging function and only print on when debugging
      // ignore: avoid_print
      print("[S] " + data["log"]!);
    }
    break;
  }
}
