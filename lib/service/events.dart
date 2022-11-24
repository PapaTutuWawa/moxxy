import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/service/avatars.dart';
import 'package:moxxyv2/service/blocking.dart';
import 'package:moxxyv2/service/conversation.dart';
import 'package:moxxyv2/service/database/database.dart';
import 'package:moxxyv2/service/helpers.dart';
import 'package:moxxyv2/service/httpfiletransfer/helpers.dart';
import 'package:moxxyv2/service/httpfiletransfer/httpfiletransfer.dart';
import 'package:moxxyv2/service/httpfiletransfer/jobs.dart';
import 'package:moxxyv2/service/httpfiletransfer/location.dart';
import 'package:moxxyv2/service/language.dart';
import 'package:moxxyv2/service/message.dart';
import 'package:moxxyv2/service/moxxmpp/reconnect.dart';
import 'package:moxxyv2/service/notifications.dart';
import 'package:moxxyv2/service/omemo/omemo.dart';
import 'package:moxxyv2/service/preferences.dart';
import 'package:moxxyv2/service/roster.dart';
import 'package:moxxyv2/service/service.dart';
import 'package:moxxyv2/service/state.dart';
import 'package:moxxyv2/service/xmpp.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/eventhandler.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/shared/models/preferences.dart';
import 'package:permission_handler/permission_handler.dart';

void setupBackgroundEventHandler() {
  final handler = EventHandler()
    ..addMatchers([
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
      EventTypeMatcher<SignOutCommand>(performSignOut),
      EventTypeMatcher<SendFilesCommand>(performSendFiles),
      EventTypeMatcher<SetConversationMuteStatusCommand>(performSetMuteState),
      EventTypeMatcher<GetConversationOmemoFingerprintsCommand>(performGetOmemoFingerprints),
      EventTypeMatcher<SetOmemoDeviceEnabledCommand>(performEnableOmemoKey),
      EventTypeMatcher<RecreateSessionsCommand>(performRecreateSessions),
      EventTypeMatcher<SetOmemoEnabledCommand>(performSetOmemoEnabled),
      EventTypeMatcher<GetOwnOmemoFingerprintsCommand>(performGetOwnOmemoFingerprints),
      EventTypeMatcher<RemoveOwnDeviceCommand>(performRemoveOwnDevice),
      EventTypeMatcher<RegenerateOwnDeviceCommand>(performRegenerateOwnDevice),
      EventTypeMatcher<RetractMessageCommentCommand>(performMessageRetraction),
      EventTypeMatcher<MarkConversationAsReadCommand>(performMarkConversationAsRead),
  ]);

  GetIt.I.registerSingleton<EventHandler>(handler);
}

Future<void> performLogin(LoginCommand command, { dynamic extra }) async {
  final id = extra as String;

  GetIt.I.get<Logger>().fine('Performing login...');
  GetIt.I.get<MoxxyReconnectionPolicy>().setShouldReconnect(false);
  final result = await GetIt.I.get<XmppService>().connectAwaitable(
    ConnectionSettings(
      jid: JID.fromString(command.jid),
      password: command.password,
      useDirectTLS: command.useDirectTLS,
      allowPlainAuth: true,
    ),
    true,
  );
  GetIt.I.get<Logger>().fine('Login done');

  // ignore: avoid_dynamic_calls
  if (result.success) {
    final preferences = await GetIt.I.get<PreferencesService>().getPreferences();
    GetIt.I.get<MoxxyReconnectionPolicy>().setShouldReconnect(true);
    final settings = GetIt.I.get<XmppConnection>().getConnectionSettings();
    sendEvent(
      LoginSuccessfulEvent(
        jid: settings.jid.toString(),
        preStart: await _buildPreStartDoneEvent(preferences),
      ),
      id:id,
    );
  } else {
    GetIt.I.get<MoxxyReconnectionPolicy>().setShouldReconnect(false);
    sendEvent(
      LoginFailureEvent(
        reason: xmppErrorToTranslatableString(result.error!),
      ),
      id: id,
    );
  }
}

Future<PreStartDoneEvent> _buildPreStartDoneEvent(PreferencesState preferences) async {
  final xmpp = GetIt.I.get<XmppService>();
  final state = await xmpp.getXmppState();

  await GetIt.I.get<RosterService>().loadRosterFromDatabase();

  // Check some permissions
  final storagePerm = await Permission.storage.status;
  final permissions = List<int>.empty(growable: true);
  if (storagePerm.isDenied /*&& !state.askedStoragePermission*/) {
    permissions.add(Permission.storage.value);

    await xmpp.modifyXmppState((state) => state.copyWith(
        askedStoragePermission: true,
    ),);
  }

  return PreStartDoneEvent(
    state: 'logged_in',
    jid: state.jid,
    displayName: state.displayName ?? state.jid!.split('@').first,
    avatarUrl: state.avatarUrl,
    avatarHash: state.avatarHash,
    permissionsToRequest: permissions,
    preferences: preferences,
    conversations: (await GetIt.I.get<DatabaseService>().loadConversations()).where((c) => c.open).toList(),
    roster: await GetIt.I.get<RosterService>().loadRosterFromDatabase(),
  );
}

Future<void> performPreStart(PerformPreStartCommand command, { dynamic extra }) async {
  final id = extra as String;
  
  // Prevent a race condition where the UI sends the prestart command before the service
  // has finished setting everything up
  GetIt.I.get<Logger>().finest('Waiting for preStart future to complete..');
  await GetIt.I.get<Completer<void>>().future;
  GetIt.I.get<Logger>().finest('PreStart future done');

  final preferences = await GetIt.I.get<PreferencesService>().getPreferences();

  // Set the locale very early
  GetIt.I.get<LanguageService>().defaultLocale = command.systemLocaleCode;
  if (preferences.languageLocaleCode == 'default') {
    LocaleSettings.setLocaleRaw(command.systemLocaleCode);
  } else {
    LocaleSettings.setLocaleRaw(preferences.languageLocaleCode);
  }
  GetIt.I.get<XmppService>().setNotificationText(
    await GetIt.I.get<XmppConnection>().getConnectionState(),
  );

  final settings = await GetIt.I.get<XmppService>().getConnectionSettings();
  if (settings != null) {
    sendEvent(
      await _buildPreStartDoneEvent(preferences),
      id: id,
    );
  } else {
    sendEvent(
      PreStartDoneEvent(
        state: 'not_logged_in',
        permissionsToRequest: List<int>.empty(),
        preferences: preferences,
      ),
      id: id,
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
        open: true,
      );

      sendEvent(
        ConversationAddedEvent(
          conversation: updatedConversation,
        ),
        id: id,
      );
      return;
    }

    sendEvent(
      NoConversationModifiedEvent(),
      id: id,
    );
    return;
  } else {
    final conversation = await cs.addConversationFromData(
      command.title,
      -1,
      false,
      command.lastMessageBody,
      command.avatarUrl,
      command.jid,
      0,
      -1,
      true,
      // TODO(PapaTutuWawa): Take as an argument
      false,
      (await GetIt.I.get<PreferencesService>().getPreferences()).enableOmemoByDefault,
    );

    sendEvent(
      ConversationAddedEvent(
        conversation: conversation,
      ),
      id: id,
    );
  }
}

Future<void> performGetMessagesForJid(GetMessagesForJidCommand command, { dynamic extra }) async {
  final id = extra as String;

  sendEvent(
    MessagesResultEvent(
      messages: await GetIt.I.get<MessageService>().getMessagesForJid(command.jid),
    ),
    id: id,
  );
}

Future<void> performSetOpenConversation(SetOpenConversationCommand command, { dynamic extra }) async {
  await GetIt.I.get<XmppService>().setCurrentlyOpenedChatJid(command.jid ?? '');

  // Null just means that the chat has been closed
  if (command.jid != null) {
    await GetIt.I.get<NotificationsService>().dismissNotificationsByJid(command.jid!);
  }
}

Future<void> performSendMessage(SendMessageCommand command, { dynamic extra }) async {
  await GetIt.I.get<XmppService>().sendMessage(
    body: command.body,
    recipients: command.recipients,
    chatState: command.chatState.isNotEmpty
      ? chatStateFromString(command.chatState)
      : null,
    quotedMessage: command.quotedMessage,
    commandId: extra as String,
  );
}

Future<void> performBlockJid(BlockJidCommand command, { dynamic extra }) async {
  await GetIt.I.get<BlocklistService>().blockJid(command.jid);
}

Future<void> performUnblockJid(UnblockJidCommand command, { dynamic extra }) async {
  await GetIt.I.get<BlocklistService>().unblockJid(command.jid);
}

Future<void> performUnblockAll(UnblockAllCommand command, { dynamic extra }) async {
  await GetIt.I.get<BlocklistService>().unblockAll();
}

Future<void> performSetCSIState(SetCSIStateCommand command, { dynamic extra }) async {
  // Tell the [XmppService] about the app state
  GetIt.I.get<XmppService>().setAppState(command.active);

  final conn = GetIt.I.get<XmppConnection>();

  // Only send the CSI nonza when we're connected
  if (await conn.getConnectionState() != XmppConnectionState.connected) return;
  final csi = conn.getManagerById<CSIManager>(csiManager)!;
  if (command.active) {
    await csi.setActive();
  } else {
    await csi.setInactive();
  }
}

Future<void> performSetPreferences(SetPreferencesCommand command, { dynamic extra }) async {
  await GetIt.I.get<PreferencesService>().modifyPreferences((_) => command.preferences);

  // Set the logging mode
  if (!kDebugMode) {
    final enableDebug = command.preferences.debugEnabled;
    Logger.root.level = enableDebug ? Level.ALL : Level.INFO;
  }

  // Set the locale
  final locale = command.preferences.languageLocaleCode == 'default' ?
    GetIt.I.get<LanguageService>().defaultLocale :
    command.preferences.languageLocaleCode;
  LocaleSettings.setLocaleRaw(locale);
  GetIt.I.get<XmppService>().setNotificationText(
    await GetIt.I.get<XmppConnection>().getConnectionState(),
  );
}

Future<void> performAddContact(AddContactCommand command, { dynamic extra }) async {
  final id = extra as String;

  final jid = command.jid;
  final roster = GetIt.I.get<RosterService>();
  if (await roster.isInRoster(jid)) {
    sendEvent(AddContactResultEvent(added: false), id: id);
    return;
  }

  final cs = GetIt.I.get<ConversationService>();
  final conversation = await cs.getConversationByJid(jid);
  if (conversation != null) {
    final c = await cs.updateConversation(
      conversation.id,
      open: true,
    );

    sendEvent(
      AddContactResultEvent(conversation: c, added: false),
      id: id,
    );
  } else {            
    final c = await cs.addConversationFromData(
      jid.split('@')[0],
      -1,
      false,
      '',
      '',
      jid,
      0,
      -1,
      true,
      // TODO(PapaTutuWawa): Take as an argument
      false,
      (await GetIt.I.get<PreferencesService>().getPreferences()).enableOmemoByDefault,
    );
    sendEvent(
      AddContactResultEvent(conversation: c, added: true),
      id: id,
    );
  }

  await roster.addToRosterWrapper('', '', jid, jid.split('@')[0]);
  
  // Try to figure out an avatar
  await GetIt.I.get<AvatarService>().subscribeJid(jid);
  await GetIt.I.get<AvatarService>().fetchAndUpdateAvatarForJid(jid, '');
}

Future<void> performRequestDownload(RequestDownloadCommand command, { dynamic extra }) async {
  final ms = GetIt.I.get<MessageService>();
  final srv = GetIt.I.get<HttpFileTransferService>();

  final message = await ms.updateMessage(
    command.message.id,
    isDownloading: true,
  );
  sendEvent(MessageUpdatedEvent(message: message));

  final metadata = await peekFile(command.message.srcUrl!);

  // TODO(Unknown): Maybe deduplicate with the code in the xmpp service
  // NOTE: This either works by returing "jpg" for ".../hallo.jpg" or fails
  //       for ".../aaaaaaaaa", in which case we would've failed anyways.
  final ext = message.srcUrl!.split('.').last;
  final mimeGuess = metadata.mime ?? guessMimeTypeFromExtension(ext);

  await srv.downloadFile(
    FileDownloadJob(
      MediaFileLocation(
        message.srcUrl!,
        message.filename ?? filenameFromUrl(message.srcUrl!),
        message.encryptionScheme,
        message.key != null ? base64Decode(message.key!) : null,
        message.iv != null ? base64Decode(message.iv!) : null,
        message.plaintextHashes,
        message.ciphertextHashes,
      ),
      message.id,
      message.conversationJid,
      mimeGuess,
    ),
  );
}

Future<void> performSetAvatar(SetAvatarCommand command, { dynamic extra }) async {
  await GetIt.I.get<XmppService>().modifyXmppState((state) => state.copyWith(
      avatarUrl: command.path,
      avatarHash: command.hash,
  ),);
  await GetIt.I.get<AvatarService>().publishAvatar(command.path, command.hash);
}

Future<void> performSetShareOnlineStatus(SetShareOnlineStatusCommand command, { dynamic extra }) async {
  final roster = GetIt.I.get<RosterService>();
  final rs = GetIt.I.get<RosterService>();
  final item = await rs.getRosterItemByJid(command.jid);

  // TODO(Unknown): Maybe log
  if (item == null) return;

  if (command.share) {
    if (item.ask == 'subscribe') {
      await roster.acceptSubscriptionRequest(command.jid);
    } else {
      roster.sendSubscriptionRequest(command.jid);
    }
  } else {
    if (item.ask == 'subscribe') {
      await roster.rejectSubscriptionRequest(command.jid);
    } else {
      roster.sendUnsubscriptionRequest(command.jid);
    }
  }
}

Future<void> performCloseConversation(CloseConversationCommand command, { dynamic extra }) async {
  final cs = GetIt.I.get<ConversationService>();
  final conversation = await cs.getConversationByJid(command.jid);
  if (conversation == null) {
    // TODO(Unknown): Should not happen
    return;
  }

  await cs.updateConversation(
    conversation.id,
    open: false,
  );

  sendEvent(
    CloseConversationEvent(),
    id: extra as String,
  );
}

Future<void> performSendChatState(SendChatStateCommand command, { dynamic extra }) async {
  final prefs = await GetIt.I.get<PreferencesService>().getPreferences();

  // Only send chat states if the users wants to send them
  if (!prefs.sendChatMarkers) return;

  final conn = GetIt.I.get<XmppConnection>();
  conn
    .getManagerById<ChatStateManager>(chatStateManager)!
    .sendChatState(chatStateFromString(command.state), command.jid);
}

Future<void> performGetFeatures(GetFeaturesCommand command, { dynamic extra }) async {
  final id = extra as String;

  final conn = GetIt.I.get<XmppConnection>();
  final sm = conn.getNegotiatorById<StreamManagementNegotiator>(streamManagementNegotiator)!;
  final csi = conn.getNegotiatorById<CSINegotiator>(csiNegotiator)!;
  final httpFileUpload = conn.getManagerById<HttpFileUploadManager>(httpFileUploadManager)!;
  final userBlocking = conn.getManagerById<BlockingManager>(blockingManager)!;
  sendEvent(
    GetFeaturesEvent(
      supportsStreamManagement: sm.isSupported,
      supportsCsi: csi.isSupported,
      supportsHttpFileUpload: await httpFileUpload.isSupported(),
      supportsUserBlocking: await userBlocking.isSupported(),
    ),
    id: id,
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
    id: id,
  );
}

Future<void> performSendFiles(SendFilesCommand command, { dynamic extra }) async {
  await GetIt.I.get<XmppService>().sendFiles(command.paths, command.recipients);
}

Future<void> performSetMuteState(SetConversationMuteStatusCommand command, { dynamic extra }) async {
  final cs = GetIt.I.get<ConversationService>();
  final conversation = await cs.getConversationByJid(command.jid);
  final newConversation = await cs.updateConversation(
    conversation!.id,
    muted: command.muted,
  );

  sendEvent(ConversationUpdatedEvent(conversation: newConversation));
}

Future<void> performGetOmemoFingerprints(GetConversationOmemoFingerprintsCommand command, { dynamic extra }) async {
  final id = extra as String;

  final omemo = GetIt.I.get<OmemoService>();
  sendEvent(
    GetConversationOmemoFingerprintsResult(
      fingerprints: await omemo.getOmemoKeysForJid(command.jid),
    ),
    id: id,
  );
}

Future<void> performEnableOmemoKey(SetOmemoDeviceEnabledCommand command, { dynamic extra }) async {
  final id = extra as String;

  final omemo = GetIt.I.get<OmemoService>();
  await omemo.setOmemoKeyEnabled(command.jid, command.deviceId, command.enabled);

  await performGetOmemoFingerprints(
    GetConversationOmemoFingerprintsCommand(jid: command.jid),
    extra: id,
  );
}

Future<void> performRecreateSessions(RecreateSessionsCommand command, { dynamic extra }) async {
  await GetIt.I.get<OmemoService>().removeAllSessions(command.jid);

  final conn = GetIt.I.get<XmppConnection>();
  await conn.getManagerById<OmemoManager>(omemoManager)!.sendEmptyMessage(
    JID.fromString(command.jid),
    findNewSessions: true,
  );
}

Future<void> performSetOmemoEnabled(SetOmemoEnabledCommand command, { dynamic extra }) async {
  final cs = GetIt.I.get<ConversationService>();
  final conversation = await cs.getConversationByJid(command.jid);
  await cs.updateConversation(
    conversation!.id,
    encrypted: command.enabled,
  );
}

Future<void> performGetOwnOmemoFingerprints(GetOwnOmemoFingerprintsCommand command, { dynamic extra }) async {
  final id = extra as String;
  final os = GetIt.I.get<OmemoService>();
  final xs = GetIt.I.get<XmppService>();
  await os.ensureInitialized();

  final jid = (await xs.getConnectionSettings())!.jid;
  sendEvent(
    GetOwnOmemoFingerprintsResult(
      ownDeviceFingerprint: await os.getDeviceFingerprint(),
      ownDeviceId: await os.getDeviceId(),
      fingerprints: await os.getOwnFingerprints(jid),
    ),
    id: id,
  );
}

Future<void> performRemoveOwnDevice(RemoveOwnDeviceCommand command, { dynamic extra }) async {
  await GetIt.I.get<XmppConnection>()
    .getManagerById<OmemoManager>(omemoManager)!
    .deleteDevice(command.deviceId);
}

Future<void> performRegenerateOwnDevice(RegenerateOwnDeviceCommand command, { dynamic extra }) async {
  final id = extra as String;
  final jid = GetIt.I.get<XmppConnection>()
    .getConnectionSettings()
    .jid.toBare()
    .toString();
  final device = await GetIt.I.get<OmemoService>().regenerateDevice(jid);

  sendEvent(
    RegenerateOwnDeviceResult(device: device),
    id: id,
  );
}

Future<void> performMessageRetraction(RetractMessageCommentCommand command, { dynamic extra }) async {
  await GetIt.I.get<MessageService>().retractMessage( 
    command.conversationJid,
    command.originId,
    '',
    true,
  );

  // Send the retraction
  (GetIt.I.get<XmppConnection>().getManagerById(messageManager)! as MessageManager)
    .sendMessage(
      MessageDetails(
        to: command.conversationJid,
        messageRetraction: MessageRetractionData(
          command.originId,
          t.messages.retractedFallback,
        ),
      ),
    );
}

Future<void> performMarkConversationAsRead(MarkConversationAsReadCommand command, { dynamic extra }) async {
  final conversation = await GetIt.I.get<ConversationService>().updateConversation(
    command.conversationId,
    unreadCounter: 0,
  );

  // TODO(PapaTutuWawa): Send read marker as well
  sendEvent(ConversationUpdatedEvent(conversation: conversation));

  // Dismiss notifications for that chat
  await GetIt.I.get<NotificationsService>().dismissNotificationsByJid(
    conversation.jid,
  );
}
