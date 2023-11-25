import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:moxlib/moxlib.dart';
import 'package:moxxy_native/moxxy_native.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/eventhandler.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/shared/synchronized_queue.dart';
import 'package:moxxyv2/ui/bloc/blocklist_bloc.dart' as blocklist;
import 'package:moxxyv2/ui/bloc/conversation_bloc.dart' as conversation;
import 'package:moxxyv2/ui/bloc/conversations.dart' as conversations;
import 'package:moxxyv2/ui/bloc/newconversation_bloc.dart' as new_conversation;
import 'package:moxxyv2/ui/bloc/profile_bloc.dart' as profile;
import 'package:moxxyv2/ui/controller/conversation_controller.dart';
import 'package:moxxyv2/ui/prestart.dart';
import 'package:moxxyv2/ui/service/avatars.dart';
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
      EventTypeMatcher<ServiceReadyEvent>(onServiceReady),
      EventTypeMatcher<MessageNotificationTappedEvent>(onNotificationTappend),
      EventTypeMatcher<StreamNegotiationsCompletedEvent>(
        onStreamNegotiationsDone,
      ),
      EventTypeMatcher<AvatarUpdatedEvent>(onAvatarUpdated),
    ]);

  GetIt.I.registerSingleton<EventHandler>(handler);
  GetIt.I.registerSingleton<SynchronizedQueue<Map<String, dynamic>?>>(
    SynchronizedQueue<Map<String, dynamic>?>(handleIsolateEvent),
  );
}

Future<void> receiveIsolateEvent(Map<String, dynamic>? json) async {
  await GetIt.I.get<SynchronizedQueue<Map<String, dynamic>?>>().add(json);
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

  log.finest('<-- $event');

  // First attempt to deal with awaitables
  var found = false;
  found = await getForegroundService().getDataSender().onData(data);
  if (found) return;

  // Then run the event handlers
  found = await GetIt.I.get<EventHandler>().run(event);
  if (found == true) return;

  log.warning('Failed to match event');
}

Future<void> onConversationAdded(
  ConversationAddedEvent event, {
  dynamic extra,
}) async {
  await GetIt.I.get<conversations.ConversationsCubit>().addConversation(
        event.conversation,
      );
}

Future<void> onConversationUpdated(
  ConversationUpdatedEvent event, {
  dynamic extra,
}) async {
  await GetIt.I.get<conversations.ConversationsCubit>().updateConversation(
        event.conversation,
      );
  GetIt.I.get<conversation.ConversationBloc>().add(
        conversation.ConversationUpdatedEvent(event.conversation),
      );
  GetIt.I.get<profile.ProfileBloc>().add(
        profile.ConversationUpdatedEvent(event.conversation),
      );
}

Future<void> onMessageAdded(MessageAddedEvent event, {dynamic extra}) async {
  await BidirectionalConversationController.currentController
      ?.onMessageReceived(
    event.message,
  );
}

Future<void> onMessageUpdated(
  MessageUpdatedEvent event, {
  dynamic extra,
}) async {
  BidirectionalConversationController.currentController?.onMessageUpdated(
    event.message,
  );
}

Future<void> onBlocklistPushed(
  BlocklistPushEvent event, {
  dynamic extra,
}) async {
  GetIt.I.get<blocklist.BlocklistBloc>().add(
        blocklist.BlocklistPushedEvent(
          event.added,
          event.removed,
        ),
      );
}

Future<void> onRosterPush(RosterDiffEvent event, {dynamic extra}) async {
  GetIt.I.get<new_conversation.NewConversationBloc>().add(
        new_conversation.RosterPushedEvent(
          event.added,
          event.modified,
          event.removed,
        ),
      );
}

Future<void> onProgress(ProgressEvent event, {dynamic extra}) async {
  GetIt.I.get<UIProgressService>().onProgress(event.id, event.progress);
}

Future<void> onSelfAvatarChanged(
  SelfAvatarChangedEvent event, {
  dynamic extra,
}) async {
  GetIt.I.get<profile.ProfileBloc>().add(
        profile.AvatarSetEvent(event.path, event.hash, false),
      );
}

Future<void> onServiceReady(ServiceReadyEvent event, {dynamic extra}) async {
  await getForegroundService().send(
    PerformPreStartCommand(
      systemLocaleCode:
          WidgetsBinding.instance.platformDispatcher.locale.toLanguageTag(),
    ),
    awaitable: false,
  );
}

Future<void> onNotificationTappend(
  MessageNotificationTappedEvent event, {
  dynamic extra,
}) async {
  GetIt.I.get<conversation.ConversationBloc>().add(
        conversation.RequestedConversationEvent(
          event.conversationJid,
          event.title,
          event.avatarPath,
        ),
      );
}

Future<void> onStreamNegotiationsDone(
  StreamNegotiationsCompletedEvent event, {
  dynamic extra,
}) async {
  if (!event.resumed) {
    GetIt.I.get<UIAvatarsService>().resetCache();
  }
}

Future<void> onAvatarUpdated(
  AvatarUpdatedEvent event, {
  dynamic extra,
}) async {}
