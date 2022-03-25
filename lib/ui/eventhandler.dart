import "package:moxxyv2/shared/eventhandler.dart";
import "package:moxxyv2/shared/backgroundsender.dart";
import "package:moxxyv2/shared/awaitabledatasender.dart";
import "package:moxxyv2/shared/events.dart";
import "package:moxxyv2/ui/bloc/blocklist_bloc.dart" as blocklist;
import "package:moxxyv2/ui/bloc/conversation_bloc.dart" as conversation;
import "package:moxxyv2/ui/bloc/conversations_bloc.dart" as conversations;
import "package:moxxyv2/ui/bloc/newconversation_bloc.dart" as newConversation;

import "package:logging/logging.dart";
import "package:get_it/get_it.dart";
import "package:flutter_background_service/flutter_background_service.dart";

// TODO: Rename to events.dart

void setupEventHandler() {
  final handler = EventHandler();
  handler.addMatchers([
      EventTypeMatcher<MessageAddedEvent>(onMessageAdded),
      EventTypeMatcher<MessageUpdatedEvent>(onMessageUpdated),
      EventTypeMatcher<ConversationUpdatedEvent>(onConversationUpdated),
      EventTypeMatcher<ConversationAddedEvent>(onConversationAdded),
      EventTypeMatcher<BlocklistPushEvent>(onBlocklistPushed),
      EventTypeMatcher<RosterDiffEvent>(onRosterPush)
  ]);

  GetIt.I.registerSingleton<EventHandler>(handler);

  // Make sure that we handle events from flutter_background_service
  FlutterBackgroundService().onDataReceived.listen((Map<String, dynamic>? json) async {
      final log = GetIt.I.get<Logger>();
      if (json == null) {
        log.warning("Received null from the background service. Ignoring...");
        return;
      }

      log.finest("S2F: $json");
      
      // NOTE: This feels dirty, but we gotta do it
      final event = getEventFromJson(json["data"]!)!;
      final data = DataWrapper<BackgroundEvent>(
        json["id"]!,
        event
      );
      
      // First attempt to deal with awaitables
      bool found = false;
      found = await GetIt.I.get<BackgroundServiceDataSender>().onData(data);
      if (found) return;

      // Then run the event handlers
      found = GetIt.I.get<EventHandler>().run(event);
      if (found) return;

      log.warning("Failed to match event");
  });
}

Future<void> onConversationAdded(BaseEvent e, { dynamic extra }) async {
  final event = e as ConversationAddedEvent;

  GetIt.I.get<conversations.ConversationsBloc>().add(
    conversations.ConversationsAddedEvent(event.conversation)
  );
}

Future<void> onConversationUpdated(BaseEvent e, { dynamic extra }) async {
  final event = e as ConversationUpdatedEvent;

  GetIt.I.get<conversations.ConversationsBloc>().add(
    conversations.ConversationsUpdatedEvent(event.conversation)
  );
}

Future<void> onMessageAdded(BaseEvent e, { dynamic extra }) async {
  final event = e as MessageAddedEvent;

  GetIt.I.get<conversation.ConversationBloc>().add(
    conversation.MessageAddedEvent(event.message)
  );
}

Future<void> onMessageUpdated(BaseEvent e, { dynamic extra }) async {
  final event = e as MessageUpdatedEvent;

  GetIt.I.get<conversation.ConversationBloc>().add(
    conversation.MessageUpdatedEvent(event.message)
  );
}

Future<void> onBlocklistPushed(BaseEvent e, { dynamic extra }) async {
  final event = e as BlocklistPushEvent;

  GetIt.I.get<blocklist.BlocklistBloc>().add(
    blocklist.BlocklistPushedEvent(
      e.added,
      e.removed
    )
  );
}

Future<void> onRosterPush(BaseEvent e, { dynamic extra }) async {
  final event = e as RosterDiffEvent;
  GetIt.I.get<newConversation.NewConversationBloc>().add(
    newConversation.RosterPushedEvent(
      event.added,
      event.modified,
      event.removed
    )
  );
}
