import 'dart:async';
import 'dart:io';
import 'package:flutter/painting.dart';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:moxlib/awaitabledatasender.dart';
import 'package:moxplatform/moxplatform.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/eventhandler.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/ui/bloc/blocklist_bloc.dart' as blocklist;
import 'package:moxxyv2/ui/bloc/conversation_bloc.dart' as conversation;
import 'package:moxxyv2/ui/bloc/conversations_bloc.dart' as conversations;
import 'package:moxxyv2/ui/bloc/newconversation_bloc.dart' as new_conversation;
import 'package:moxxyv2/ui/bloc/profile_bloc.dart' as profile;
import 'package:moxxyv2/ui/bloc/sharedmedia_bloc.dart' as sharedmedia;
import 'package:moxxyv2/ui/prestart.dart';
import 'package:moxxyv2/ui/service/progress.dart';

void setupEventHandler() {
  final handler = EventHandler()
    ..addMatchers(<EventTypeMatcher<dynamic>>[
      EventTypeMatcher<MessageAddedEvent>(onMessageAdded),
      EventTypeMatcher<MessageUpdatedEvent>(onMessageUpdated),
      EventTypeMatcher<ConversationUpdatedEvent>(onConversationUpdated),
      EventTypeMatcher<ConversationAddedEvent>(onConversationAdded),
      EventTypeMatcher<BlocklistPushEvent>(onBlocklistPushed),
      EventTypeMatcher<RosterDiffEvent>(onRosterPush),
      EventTypeMatcher<ProgressEvent>(onProgress),
      EventTypeMatcher<SelfAvatarChangedEvent>(onSelfAvatarChanged),
      EventTypeMatcher<PreStartDoneEvent>(preStartDone),
      EventTypeMatcher<ServiceReadyEvent>(onServiceReady)
  ]);

  GetIt.I.registerSingleton<EventHandler>(handler);
}

Future<void> handleIsolateEvent(Map<String, dynamic>? json) async {
  final log = GetIt.I.get<Logger>();
  if (json == null) {
    log.warning('Received null from the background service. Ignoring...');
    return;
  }
  
  // NOTE: This feels dirty, but we gotta do it
  final event = getEventFromJson(json['data']! as Map<String, dynamic>)!;
  final data = DataWrapper<BackgroundEvent>(
    json['id']! as String,
    event,
  );

  log.finest('S2F: $event');

  // First attempt to deal with awaitables
  var found = false;
  found = await MoxplatformPlugin.handler.getDataSender().onData(data);
  if (found) return;

  // Then run the event handlers
  found = await GetIt.I.get<EventHandler>().run(event);
  if (found == true) return;

  log.warning('Failed to match event');
}

Future<void> onConversationAdded(ConversationAddedEvent event, { dynamic extra }) async {
  GetIt.I.get<conversations.ConversationsBloc>().add(
    conversations.ConversationsAddedEvent(event.conversation),
  );
}

Future<void> onConversationUpdated(ConversationUpdatedEvent event, { dynamic extra }) async {
  GetIt.I.get<conversations.ConversationsBloc>().add(
    conversations.ConversationsUpdatedEvent(event.conversation),
  );
  GetIt.I.get<conversation.ConversationBloc>().add(
    conversation.ConversationUpdatedEvent(event.conversation),
  );
  GetIt.I.get<profile.ProfileBloc>().add(
    profile.ConversationUpdatedEvent(event.conversation),
  );
  GetIt.I.get<sharedmedia.SharedMediaBloc>().add(
    sharedmedia.UpdatedSharedMedia(
      event.conversation.jid,
      event.conversation.sharedMedia,
    ),
  );
}

Future<void> onMessageAdded(MessageAddedEvent event, { dynamic extra }) async {
  GetIt.I.get<conversation.ConversationBloc>().add(
    conversation.MessageAddedEvent(event.message),
  );
}

Future<void> onMessageUpdated(MessageUpdatedEvent event, { dynamic extra }) async {
  GetIt.I.get<conversation.ConversationBloc>().add(
    conversation.MessageUpdatedEvent(event.message),
  );
}

Future<void> onBlocklistPushed(BlocklistPushEvent event, { dynamic extra }) async {
  GetIt.I.get<blocklist.BlocklistBloc>().add(
    blocklist.BlocklistPushedEvent(
      event.added,
      event.removed,
    ),
  );
}

Future<void> onRosterPush(RosterDiffEvent event, { dynamic extra }) async {
  GetIt.I.get<new_conversation.NewConversationBloc>().add(
    new_conversation.RosterPushedEvent(
      event.added,
      event.modified,
      event.removed,
    ),
  );
}

Future<void> onProgress(ProgressEvent event, { dynamic extra }) async {
  GetIt.I.get<UIProgressService>().onProgress(event.id, event.progress);
}

Future<void> onSelfAvatarChanged(SelfAvatarChangedEvent event, { dynamic extra }) async {
  // Evict the profile picture from the cache
  await FileImage(File(event.path)).evict();

  GetIt.I.get<conversations.ConversationsBloc>().add(
    conversations.AvatarChangedEvent(event.path),
  );
  GetIt.I.get<profile.ProfileBloc>().add(
    profile.AvatarSetEvent(event.path, event.hash),
  );
}

Future<void> onServiceReady(ServiceReadyEvent event, { dynamic extra }) async {
  GetIt.I.get<Logger>().fine('onServiceReady: Waiting for UI future to resolve...');
  await GetIt.I.get<Completer<void>>().future;
  GetIt.I.get<Logger>().fine('onServiceReady: Done');
  await MoxplatformPlugin.handler.getDataSender().sendData(
    PerformPreStartCommand(),
    awaitable: false,
  );
}
