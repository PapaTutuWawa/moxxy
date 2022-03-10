import "package:moxxyv2/shared/events.dart" as events;
import "package:moxxyv2/shared/commands.dart" as commands;
import "package:moxxyv2/ui/constants.dart";
import "package:moxxyv2/ui/service/download.dart";
import "package:moxxyv2/ui/redux/state.dart";
import "package:moxxyv2/ui/redux/conversation/actions.dart";
import "package:moxxyv2/ui/redux/login/actions.dart";
import "package:moxxyv2/ui/redux/addcontact/actions.dart";
import "package:moxxyv2/ui/redux/roster/actions.dart";
import "package:moxxyv2/ui/redux/account/state.dart";
import "package:moxxyv2/ui/redux/account/actions.dart";
import "package:moxxyv2/ui/redux/debug/actions.dart";
import "package:moxxyv2/ui/redux/preferences/actions.dart";
import "package:moxxyv2/ui/pages/conversation/arguments.dart";

import "package:flutter/material.dart";
import "package:get_it/get_it.dart";
import "package:flutter_background_service/flutter_background_service.dart";
import "package:redux/redux.dart";
import "package:flutter_redux_navigation/flutter_redux_navigation.dart";
import "package:logging/logging.dart";
import "package:permission_handler/permission_handler.dart";

// TODO: Handle [LoginFailedEvent]
/// Called whenever the background service sends data to the UI isolate.
void handleBackgroundServiceData(Map<String, dynamic>? data) {
  final store = GetIt.I.get<Store<MoxxyState>>();
  if (data == null) {
    GetIt.I.get<Logger>().warning("handleBackgroundServiceData: Received null");
    return;
  }

  switch (data["type"]) {
    case events.preStartResultType: {
      final event = events.PreStartResultEvent.fromJson(data);
      if (event.state == "logged_in") {
        FlutterBackgroundService().sendData(
          commands.LoadConversationsAction().toJson()
        );

        store.dispatch(SetAccountAction(
            state: AccountState(
              jid: event.jid!,
              displayName: event.displayName!,
              avatarUrl: event.avatarUrl!
            )
        ));

        store.dispatch(NavigateToAction.replace(conversationsRoute));

        // TODO: Move somewhere else
        // TODO: Handle this when we go into the foreground
        if (event.permissionsToRequest.isNotEmpty) {
          (() async {
              for (final perm in event.permissionsToRequest) {
                // TODO: Use the function that requests multiple permissions at once
                await Permission.byValue(perm).request();
              }
          })();
        }
      } else {
        store.dispatch(NavigateToAction.replace(loginRoute));
      }

      store.dispatch(SetPreferencesAction(event.preferences));
      store.dispatch(DebugSetEnabledAction(data["debugEnabled"], true));
    }
    break;
    case events.loginSuccessfulType: {
      final event = events.LoginSuccessfulEvent.fromJson(data);
      store.dispatch(
        LoginSuccessfulAction(
          jid: event.jid,
          displayName: event.displayName
        )
      );
    }
    break;
    case events.conversationCreatedType: {
      final event = events.ConversationCreatedEvent.fromJson(data);
      store.dispatch(AddConversationAction(
          conversation: event.conversation
        )
      );
    }
    break;
    case events.conversationUpdatedType: {
      final event = events.ConversationUpdatedEvent.fromJson(data);
      store.dispatch(
        UpdateConversationAction(
          conversation: event.conversation
        )
      );
    }
    break;
    case events.messageReceivedType: {
      final event = events.MessageReceivedEvent.fromJson(data);
      store.dispatch(
        AddMessageAction(
          message: event.message
        )
      );
    }
    break;
    case events.messageUpdatedType: {
      final event = events.MessageUpdatedEvent.fromJson(data);
      store.dispatch(
        UpdateMessageAction(
          message: event.message
        )
      );
    }
    break;
    case events.rosterDiffType: {
      final event = events.RosterDiffEvent.fromJson(data);
      store.dispatch(
        RosterDiffAction(
          newItems: event.newItems,
          changedItems: event.changedItems,
          removedItems: event.removedItems
        )
      );
    }
    break;
    case events.loadConversationsResultType: {
      final event = events.LoadConversationsResultEvent.fromJson(data);
      store.dispatch(AddMultipleConversationsAction(
          conversations: event.conversations
      ));
    }
    break;
    case events.loadMessagesForJidType: {
      final event = events.LoadMessagesForJidEvent.fromJson(data);
      store.dispatch(
        AddMultipleMessagesAction(
          conversationJid: event.jid,
          messages: event.messages,
          replace: true
        )
      );
    }
    break;
    case events.addToRosterResultType: {
      final event = events.AddToRosterResultEvent.fromJson(data);
      store.dispatch(
        AddToRosterDoneAction(
          result: event.result,
          msg: event.msg,
          jid: event.jid
        )
      );
    }
    break;
    case events.messageSendType: {
      final event = events.MessageSendResultEvent.fromJson(data);
      store.dispatch(
        AddMessageAction(
          message: event.message
        )
      );
    }
    break;
    case events.downloadProgressType: {
      final event = events.DownloadProgressEvent.fromJson(data);
      GetIt.I.get<UIDownloadService>().onProgress(event.id, event.progress);
    }
    break;
    case events.newConversationDoneEventType: {
      final event = events.NewConversationDoneEvent.fromJson(data);

      FlutterBackgroundService().sendData(
        commands.LoadMessagesForJidAction(jid: event.jid).toJson()
      );

      store.dispatch(NavigateToAction.pushNamedAndRemoveUntil(
          conversationRoute,
          ModalRoute.withName(conversationsRoute),
          arguments: ConversationPageArguments(jid: event.jid)
        )
      );
    }
    break;
  }
}
