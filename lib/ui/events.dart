import "package:moxxyv2/shared/eventhandler.dart";
import "package:moxxyv2/shared/backgroundsender.dart";
import "package:moxxyv2/shared/awaitabledatasender.dart";
import "package:moxxyv2/shared/events.dart";
import "package:moxxyv2/ui/bloc/blocklist_bloc.dart" as blocklist;
import "package:moxxyv2/ui/bloc/conversation_bloc.dart" as conversation;
import "package:moxxyv2/ui/bloc/conversations_bloc.dart" as conversations;
import "package:moxxyv2/ui/bloc/newconversation_bloc.dart" as new_conversation;
import "package:moxxyv2/ui/bloc/profile_bloc.dart" as profile;
import "package:moxxyv2/ui/bloc/sharedmedia_bloc.dart" as sharedmedia;
import "package:moxxyv2/ui/service/download.dart";

import "package:logging/logging.dart";
import "package:get_it/get_it.dart";
import "package:flutter_background_service/flutter_background_service.dart";

void setupEventHandler() {
  final handler = EventHandler();
  handler.addMatchers([
      EventTypeMatcher<MessageAddedEvent>(onMessageAdded),
      EventTypeMatcher<MessageUpdatedEvent>(onMessageUpdated),
      EventTypeMatcher<ConversationUpdatedEvent>(onConversationUpdated),
      EventTypeMatcher<ConversationAddedEvent>(onConversationAdded),
      EventTypeMatcher<BlocklistPushEvent>(onBlocklistPushed),
      EventTypeMatcher<RosterDiffEvent>(onRosterPush),
      EventTypeMatcher<DownloadProgressEvent>(onDownloadProgress),
      EventTypeMatcher<SelfAvatarChangedEvent>(onSelfAvatarChanged),
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

Future<void> onConversationAdded(ConversationAddedEvent event, { dynamic extra }) async {
  GetIt.I.get<conversations.ConversationsBloc>().add(
    conversations.ConversationsAddedEvent(event.conversation)
  );
}

Future<void> onConversationUpdated(ConversationUpdatedEvent event, { dynamic extra }) async {
  GetIt.I.get<conversations.ConversationsBloc>().add(
    conversations.ConversationsUpdatedEvent(event.conversation)
  );
  GetIt.I.get<conversation.ConversationBloc>().add(
    conversation.ConversationUpdatedEvent(event.conversation)
  );
  GetIt.I.get<profile.ProfileBloc>().add(
    profile.ConversationUpdatedEvent(event.conversation)
  );
  GetIt.I.get<sharedmedia.SharedMediaBloc>().add(
    sharedmedia.UpdatedSharedMedia(
      event.conversation.jid,
      event.conversation.sharedMedia
    )
  );
}

Future<void> onMessageAdded(MessageAddedEvent event, { dynamic extra }) async {
  GetIt.I.get<conversation.ConversationBloc>().add(
    conversation.MessageAddedEvent(event.message)
  );
}

Future<void> onMessageUpdated(MessageUpdatedEvent event, { dynamic extra }) async {
  GetIt.I.get<conversation.ConversationBloc>().add(
    conversation.MessageUpdatedEvent(event.message)
  );
}

Future<void> onBlocklistPushed(BlocklistPushEvent event, { dynamic extra }) async {
  GetIt.I.get<blocklist.BlocklistBloc>().add(
    blocklist.BlocklistPushedEvent(
      event.added,
      event.removed
    )
  );
}

Future<void> onRosterPush(RosterDiffEvent event, { dynamic extra }) async {
  GetIt.I.get<new_conversation.NewConversationBloc>().add(
    new_conversation.RosterPushedEvent(
      event.added,
      event.modified,
      event.removed
    )
  );
}

Future<void> onDownloadProgress(DownloadProgressEvent event, { dynamic extra }) async {
  GetIt.I.get<UIDownloadService>().onProgress(event.id, event.progress);
}

Future<void> onSelfAvatarChanged(SelfAvatarChangedEvent event, { dynamic extra }) async {
  GetIt.I.get<conversations.ConversationsBloc>().add(
    conversations.AvatarChangedEvent(event.path)
  );
  GetIt.I.get<profile.ProfileBloc>().add(
    profile.AvatarSetEvent(event.path, event.hash)
  );
}
