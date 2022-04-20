import "dart:async";

import "package:moxxyv2/shared/commands.dart";
import "package:moxxyv2/shared/events.dart";
import "package:moxxyv2/shared/eventhandler.dart";
import "package:moxxyv2/shared/helpers.dart";
import "package:moxxyv2/service/service.dart";
import "package:moxxyv2/service/xmpp.dart";
import "package:moxxyv2/service/preferences.dart";
import "package:moxxyv2/service/roster.dart";
import "package:moxxyv2/service/database.dart";
import "package:moxxyv2/service/conversation.dart";
import "package:moxxyv2/service/message.dart";
import "package:moxxyv2/service/blocking.dart";
import "package:moxxyv2/service/avatars.dart";
import "package:moxxyv2/service/download.dart";
import "package:moxxyv2/service/state.dart";
import "package:moxxyv2/xmpp/connection.dart";
import "package:moxxyv2/xmpp/settings.dart";
import "package:moxxyv2/xmpp/jid.dart";
import "package:moxxyv2/xmpp/managers/namespaces.dart";

import "package:logging/logging.dart";
import "package:get_it/get_it.dart";
import "package:permission_handler/permission_handler.dart";

void setupBackgroundEventHandler() {
  final handler = EventHandler();
  handler.addMatchers([
      EventTypeMatcher<LoginCommand>(performLogin),
      EventTypeMatcher<PerformPreStartCommand>(performPreStart),
      EventTypeMatcher<AddConversationCommand>(performAddConversation),
      EventTypeMatcher<AddContactCommand>(performAddContact),
      EventTypeMatcher<GetMessagesForJidCommand>(performGetMessagesForJid),
      EventTypeMatcher<SetOpenConversationCommand>(performSetOpenConversation),
      EventTypeMatcher<SendMessageCommand>(performSendMessage),
      EventTypeMatcher<BlockJidCommand>(performBlockJid),
      EventTypeMatcher<UnblockJidCommand>(performUnblockJid),
      EventTypeMatcher<UnblockAllCommand>(performUnblockAll),
      EventTypeMatcher<SetCSIStateCommand>(performSetCSIState),
      EventTypeMatcher<SetPreferencesCommand>(performSetPreferences),
      EventTypeMatcher<RequestDownloadCommand>(performRequestDownload),
      EventTypeMatcher<SetAvatarCommand>(performSetAvatar),
      EventTypeMatcher<SetShareOnlineStatusCommand>(performSetShareOnlineStatus),
      EventTypeMatcher<CloseConversationCommand>(performCloseConversation),
      EventTypeMatcher<SendChatStateCommand>(performSendChatState),
      EventTypeMatcher<GetFeaturesCommand>(performGetFeatures),
      EventTypeMatcher<SignOutCommand>(performSignOut)
  ]);

  GetIt.I.registerSingleton<EventHandler>(handler);
}

Future<void> performLogin(LoginCommand command, { dynamic extra }) async {
  final id = extra as String;

  GetIt.I.get<Logger>().fine("Performing login...");
  final result = await GetIt.I.get<XmppService>().connectAwaitable(
    ConnectionSettings(
      jid: JID.fromString(command.jid),
      password: command.password,
      useDirectTLS: command.useDirectTLS,
      allowPlainAuth: false
    ), true
  );
  GetIt.I.get<Logger>().fine("Login done");

  if (result.success) {
    final settings = GetIt.I.get<XmppConnection>().getConnectionSettings();
    sendEvent(
      LoginSuccessfulEvent(
        jid: settings.jid.toString(),
        displayName: settings.jid.local
      ),
      id:id
    );

    // TODO: Send the data of the [PreStartDoneEvent]
  } else {
    sendEvent(
      LoginFailureEvent(
        reason: result.reason!
      ),
      id: id
    );
  }
}

Future<void> performPreStart(PerformPreStartCommand command, { dynamic extra }) async {
  final id = extra as String;

  // Prevent a race condition where the UI sends the prestart command before the service
  // has finished setting everything up
  GetIt.I.get<Logger>().finest("Waiting for preStart future to complete..");
  await GetIt.I.get<Completer>().future;
  GetIt.I.get<Logger>().finest("PreStart future done");

  final xmpp = GetIt.I.get<XmppService>();
  final settings = await xmpp.getConnectionSettings();
  final state = await xmpp.getXmppState();
  final preferences = await GetIt.I.get<PreferencesService>().getPreferences();

  if (settings != null) {
    await GetIt.I.get<RosterService>().loadRosterFromDatabase();

    // Check some permissions
    final storagePerm = await Permission.storage.status;
    final List<int> permissions = List.empty(growable: true);
    if (storagePerm.isDenied /*&& !state.askedStoragePermission*/) {
      permissions.add(Permission.storage.value);

      await xmpp.modifyXmppState((state) => state.copyWith(
          askedStoragePermission: true
      ));
    }
    
    sendEvent(
      PreStartDoneEvent(
        state: "logged_in",
        jid: state.jid,
        displayName: state.displayName,
        avatarUrl: state.avatarUrl,
        avatarHash: state.avatarHash,
        permissionsToRequest: permissions,
        preferences: preferences,
        conversations: (await GetIt.I.get<DatabaseService>().loadConversations()).where((c) => c.open).toList(),
        roster: await GetIt.I.get<RosterService>().loadRosterFromDatabase()
      ),
      id: id
    );
  } else {
    sendEvent(
      PreStartDoneEvent(
        state: "not_logged_in",
        permissionsToRequest: List<int>.empty(),
        preferences: preferences
      ),
      id: id
    );
  }
}

Future<void> performAddConversation(AddConversationCommand command, { dynamic extra }) async {
  final id = extra as String;

  final cs = GetIt.I.get<ConversationService>();
  final conversation = await cs.getConversationByJid(command.jid);
  if (conversation != null) {
    if (!conversation.open) {
      // Re-open the conversation
      final updatedConversation = await cs.updateConversation(
        conversation.id,
        open: true
      );

      sendEvent(
        ConversationAddedEvent(
          conversation: updatedConversation
        ),
        id: id
      );
      return;
    }

    sendEvent(
      NoConversationModifiedEvent(),
      id: id
    );
    return;
  } else {
    final conversation = await cs.addConversationFromData(
      command.title,
      command.lastMessageBody,
      command.avatarUrl,
      command.jid,
      0,
      -1,
      const [],
      true
    );

    sendEvent(
      ConversationAddedEvent(
        conversation: conversation
      ),
      id: id
    );
  }
}

Future<void> performGetMessagesForJid(GetMessagesForJidCommand command, { dynamic extra }) async {
  final id = extra as String;

  sendEvent(
    MessagesResultEvent(
      messages: await GetIt.I.get<MessageService>().getMessagesForJid(command.jid)
    ),
    id: id
  );
}

Future<void> performSetOpenConversation(SetOpenConversationCommand command, { dynamic extra }) async {
  GetIt.I.get<XmppService>().setCurrentlyOpenedChatJid(command.jid ?? "");
}

Future<void> performSendMessage(SendMessageCommand command, { dynamic extra }) async {
  GetIt.I.get<XmppService>().sendMessage(
    body: command.body,
    jid: command.jid,
    chatState: command.chatState.isNotEmpty
      ? chatStateFromString(command.chatState)
      : null,
    quotedMessage: command.quotedMessage,
    commandId: extra as String
  );
}

Future<void> performBlockJid(BlockJidCommand command, { dynamic extra }) async {
  GetIt.I.get<BlocklistService>().blockJid(command.jid);
}

Future<void> performUnblockJid(UnblockJidCommand command, { dynamic extra }) async {
  GetIt.I.get<BlocklistService>().unblockJid(command.jid);
}

Future<void> performUnblockAll(UnblockAllCommand command, { dynamic extra }) async {
  GetIt.I.get<BlocklistService>().unblockAll();
}

Future<void> performSetCSIState(SetCSIStateCommand command, { dynamic extra }) async {
  // Tell the [XmppService] about the app state
  GetIt.I.get<XmppService>().setAppState(command.active);

  final conn = GetIt.I.get<XmppConnection>();

  // Only send the CSI nonza when we're connected
  if (conn.getConnectionState() != XmppConnectionState.connected) return;
  final csi = conn.getManagerById(csiManager)!;
  if (command.active) {
    csi.setActive();
  } else {
    csi.setInactive();
  }
}

Future<void> performSetPreferences(SetPreferencesCommand command, { dynamic extra }) async {
  GetIt.I.get<PreferencesService>().modifyPreferences((_) => command.preferences);
}

Future<void> performAddContact(AddContactCommand command, { dynamic extra }) async {
  final id = extra as String;

  final jid = command.jid;
  final roster = GetIt.I.get<RosterService>();
  if (await roster.isInRoster(jid)) {
    sendEvent(AddContactResultEvent(conversation: null, added: false), id: id);
    return;
  }

  final cs = GetIt.I.get<ConversationService>();
  final conversation = await cs.getConversationByJid(jid);
  if (conversation != null) {
    final c = await cs.updateConversation(
      conversation.id,
      open: true
    );

    sendEvent(
      AddContactResultEvent(conversation: c, added: false),
      id: id
    );
  } else {            
    final c = await cs.addConversationFromData(
      jid.split("@")[0],
      "",
      "",
      jid,
      0,
      -1,
      [],
      true
    );
    sendEvent(
      AddContactResultEvent(conversation: c, added: true),
      id: id
    );
  }

  roster.addToRosterWrapper("", "", jid, jid.split("@")[0]);
  
  // Try to figure out an avatar
  await GetIt.I.get<AvatarService>().subscribeJid(jid);
  GetIt.I.get<AvatarService>().fetchAndUpdateAvatarForJid(jid, "");
}

Future<void> performRequestDownload(RequestDownloadCommand command, { dynamic extra }) async {
  sendEvent(MessageUpdatedEvent(message: command.message.copyWith(isDownloading: true)));

  final download = GetIt.I.get<DownloadService>();
  final metadata = await download.peekFile(command.message.srcUrl!);

  // TODO: Maybe deduplicate with the code in the xmpp service
  // NOTE: This either works by returing "jpg" for ".../hallo.jpg" or fails
  //       for ".../aaaaaaaaa", in which case we would've failed anyways.
  final ext = command.message.srcUrl!.split(".").last;
  final mimeGuess = metadata.mime ?? guessMimeTypeFromExtension(ext);

  await download.downloadFile(
    command.message.srcUrl!,
    command.message.id,
    command.message.conversationJid,
    mimeGuess
  );
}

Future<void> performSetAvatar(SetAvatarCommand command, { dynamic extra }) async {
  await GetIt.I.get<XmppService>().modifyXmppState((state) => state.copyWith(
      avatarUrl: command.path,
      avatarHash: command.hash
  ));
  GetIt.I.get<AvatarService>().publishAvatar(command.path, command.hash);
}

Future<void> performSetShareOnlineStatus(SetShareOnlineStatusCommand command, { dynamic extra }) async {
  final roster = GetIt.I.get<RosterService>();
  final rs = GetIt.I.get<RosterService>();
  final item = await rs.getRosterItemByJid(command.jid);

  // TODO: Maybe log
  if (item == null) return;

  if (command.share) {
    if (item.ask == "subscribe") {
      roster.acceptSubscriptionRequest(command.jid);
    } else {
      roster.sendSubscriptionRequest(command.jid);
    }
  } else {
    if (item.ask == "subscribe") {
      roster.rejectSubscriptionRequest(command.jid);
    } else {
      roster.sendUnsubscriptionRequest(command.jid);
    }
  }
}

Future<void> performCloseConversation(CloseConversationCommand command, { dynamic extra }) async {
  final cs = GetIt.I.get<ConversationService>();
  final conversation = await cs.getConversationByJid(command.jid);
  if (conversation == null) {
    // TODO: Should not happen
    return;
  }

  await cs.updateConversation(
    conversation.id,
    open: false
  );

  sendEvent(
    CloseConversationEvent(),
    id: extra as String
  );
}

Future<void> performSendChatState(SendChatStateCommand command, { dynamic extra }) async {
  final prefs = await GetIt.I.get<PreferencesService>().getPreferences();

  // Only send chat states if the users wants to send them
  if (!prefs.sendChatMarkers) return;

  final conn = GetIt.I.get<XmppConnection>();
  final man = conn.getManagerById(chatStateManager)!;
  man.sendChatState(chatStateFromString(command.state), command.jid);
}

Future<void> performGetFeatures(GetFeaturesCommand command, { dynamic extra }) async {
  final id = extra as String;

  final conn = GetIt.I.get<XmppConnection>();
  sendEvent(
    GetFeaturesEvent(
      serverFeatures: conn.serverFeatures,
      streamFeatures: conn.streamFeatures
    ),
    id: id
  );
}

Future<void> performSignOut(SignOutCommand command, { dynamic extra }) async {
  final id = extra as String;

  final conn = GetIt.I.get<XmppConnection>();
  final xmpp = GetIt.I.get<XmppService>();
  await conn.disconnect();
  await xmpp.modifyXmppState((state) => XmppState());

  sendEvent(
    SignedOutEvent(),
    id: id
  );
}
