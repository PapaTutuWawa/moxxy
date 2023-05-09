import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/service/avatars.dart';
import 'package:moxxyv2/service/blocking.dart';
import 'package:moxxyv2/service/contacts.dart';
import 'package:moxxyv2/service/conversation.dart';
import 'package:moxxyv2/service/database/database.dart';
import 'package:moxxyv2/service/database/helpers.dart';
import 'package:moxxyv2/service/helpers.dart';
import 'package:moxxyv2/service/httpfiletransfer/helpers.dart';
import 'package:moxxyv2/service/httpfiletransfer/httpfiletransfer.dart';
import 'package:moxxyv2/service/httpfiletransfer/jobs.dart';
import 'package:moxxyv2/service/httpfiletransfer/location.dart';
import 'package:moxxyv2/service/language.dart';
import 'package:moxxyv2/service/message.dart';
import 'package:moxxyv2/service/notifications.dart';
import 'package:moxxyv2/service/omemo/omemo.dart';
import 'package:moxxyv2/service/preferences.dart';
import 'package:moxxyv2/service/roster.dart';
import 'package:moxxyv2/service/service.dart';
import 'package:moxxyv2/service/stickers.dart';
import 'package:moxxyv2/service/subscription.dart';
import 'package:moxxyv2/service/xmpp.dart';
import 'package:moxxyv2/service/xmpp_state.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/eventhandler.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/shared/models/conversation.dart';
import 'package:moxxyv2/shared/models/file_metadata.dart';
import 'package:moxxyv2/shared/models/preferences.dart';
import 'package:moxxyv2/shared/models/reaction.dart';
import 'package:moxxyv2/shared/models/sticker.dart' as sticker;
import 'package:moxxyv2/shared/models/sticker_pack.dart' as sticker_pack;
import 'package:moxxyv2/shared/models/xmpp_state.dart';
import 'package:moxxyv2/shared/synchronized_queue.dart';
import 'package:permission_handler/permission_handler.dart';

void setupBackgroundEventHandler() {
  final handler = EventHandler()
    ..addMatchers([
      EventTypeMatcher<LoginCommand>(performLogin),
      EventTypeMatcher<PerformPreStartCommand>(performPreStart),
      EventTypeMatcher<AddConversationCommand>(performAddConversation),
      EventTypeMatcher<AddContactCommand>(performAddContact),
      EventTypeMatcher<RemoveContactCommand>(performRemoveContact),
      EventTypeMatcher<SetOpenConversationCommand>(performSetOpenConversation),
      EventTypeMatcher<SendMessageCommand>(performSendMessage),
      EventTypeMatcher<BlockJidCommand>(performBlockJid),
      EventTypeMatcher<UnblockJidCommand>(performUnblockJid),
      EventTypeMatcher<UnblockAllCommand>(performUnblockAll),
      EventTypeMatcher<SetCSIStateCommand>(performSetCSIState),
      EventTypeMatcher<SetPreferencesCommand>(performSetPreferences),
      EventTypeMatcher<RequestDownloadCommand>(performRequestDownload),
      EventTypeMatcher<SetAvatarCommand>(performSetAvatar),
      EventTypeMatcher<SetShareOnlineStatusCommand>(
        performSetShareOnlineStatus,
      ),
      EventTypeMatcher<CloseConversationCommand>(performCloseConversation),
      EventTypeMatcher<SendChatStateCommand>(performSendChatState),
      EventTypeMatcher<GetFeaturesCommand>(performGetFeatures),
      EventTypeMatcher<SignOutCommand>(performSignOut),
      EventTypeMatcher<SendFilesCommand>(performSendFiles),
      EventTypeMatcher<SetConversationMuteStatusCommand>(performSetMuteState),
      EventTypeMatcher<GetConversationOmemoFingerprintsCommand>(
        performGetOmemoFingerprints,
      ),
      EventTypeMatcher<SetOmemoDeviceEnabledCommand>(performEnableOmemoKey),
      EventTypeMatcher<RecreateSessionsCommand>(performRecreateSessions),
      EventTypeMatcher<SetOmemoEnabledCommand>(performSetOmemoEnabled),
      EventTypeMatcher<GetOwnOmemoFingerprintsCommand>(
        performGetOwnOmemoFingerprints,
      ),
      EventTypeMatcher<RemoveOwnDeviceCommand>(performRemoveOwnDevice),
      EventTypeMatcher<RegenerateOwnDeviceCommand>(performRegenerateOwnDevice),
      EventTypeMatcher<RetractMessageCommentCommand>(performMessageRetraction),
      EventTypeMatcher<MarkConversationAsReadCommand>(
        performMarkConversationAsRead,
      ),
      EventTypeMatcher<MarkMessageAsReadCommand>(performMarkMessageAsRead),
      EventTypeMatcher<AddReactionToMessageCommand>(performAddMessageReaction),
      EventTypeMatcher<RemoveReactionFromMessageCommand>(
        performRemoveMessageReaction,
      ),
      EventTypeMatcher<MarkOmemoDeviceAsVerifiedCommand>(
        performMarkDeviceVerified,
      ),
      EventTypeMatcher<ImportStickerPackCommand>(performImportStickerPack),
      EventTypeMatcher<SendStickerCommand>(performSendSticker),
      EventTypeMatcher<RemoveStickerPackCommand>(performRemoveStickerPack),
      EventTypeMatcher<FetchStickerPackCommand>(performFetchStickerPack),
      EventTypeMatcher<InstallStickerPackCommand>(performStickerPackInstall),
      EventTypeMatcher<GetBlocklistCommand>(performGetBlocklist),
      EventTypeMatcher<GetPagedMessagesCommand>(performGetPagedMessages),
      EventTypeMatcher<GetPagedSharedMediaCommand>(performGetPagedSharedMedia),
    ]);

  GetIt.I.registerSingleton<EventHandler>(handler);
  GetIt.I.registerSingleton<SynchronizedQueue<Map<String, dynamic>?>>(
    SynchronizedQueue<Map<String, dynamic>?>(handleUIEvent),
  );
}

Future<void> performLogin(LoginCommand command, {dynamic extra}) async {
  final id = extra as String;

  GetIt.I.get<Logger>().fine('Performing login...');
  final result = await GetIt.I.get<XmppService>().connectAwaitable(
        ConnectionSettings(
          jid: JID.fromString(command.jid),
          password: command.password,
        ),
        true,
      );
  GetIt.I.get<Logger>().fine('Login done');

  // ignore: avoid_dynamic_calls
  final xc = GetIt.I.get<XmppConnection>();
  if (result.isType<bool>() && result.get<bool>()) {
    final preferences =
        await GetIt.I.get<PreferencesService>().getPreferences();
    final settings = xc.connectionSettings;
    sendEvent(
      LoginSuccessfulEvent(
        jid: settings.jid.toString(),
        preStart: await _buildPreStartDoneEvent(preferences),
      ),
      id: id,
    );
  } else {
    await xc.reconnectionPolicy.setShouldReconnect(false);
    sendEvent(
      LoginFailureEvent(
        reason: xmppErrorToTranslatableString(result.get<XmppError>()),
      ),
      id: id,
    );
  }
}

Future<PreStartDoneEvent> _buildPreStartDoneEvent(
  PreferencesState preferences,
) async {
  final xss = GetIt.I.get<XmppStateService>();
  final state = await xss.getXmppState();

  await GetIt.I.get<RosterService>().loadRosterFromDatabase();

  // Check some permissions
  final storagePerm = await Permission.storage.status;
  final permissions = List<int>.empty(growable: true);
  if (storagePerm.isDenied /*&& !state.askedStoragePermission*/) {
    permissions.add(Permission.storage.value);

    await xss.modifyXmppState(
      (state) => state.copyWith(
        askedStoragePermission: true,
      ),
    );
  }

  return PreStartDoneEvent(
    state: 'logged_in',
    jid: state.jid,
    displayName: state.displayName ?? state.jid!.split('@').first,
    avatarUrl: state.avatarUrl,
    avatarHash: state.avatarHash,
    permissionsToRequest: permissions,
    preferences: preferences,
    conversations:
        (await GetIt.I.get<ConversationService>().loadConversations())
            .where((c) => c.open)
            .toList(),
    roster: await GetIt.I.get<RosterService>().loadRosterFromDatabase(),
    stickers: await GetIt.I.get<StickersService>().getStickerPacks(),
  );
}

Future<void> performPreStart(
  PerformPreStartCommand command, {
  dynamic extra,
}) async {
  final id = extra as String;
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

Future<void> performAddConversation(
  AddConversationCommand command, {
  dynamic extra,
}) async {
  final id = extra as String;

  final cs = GetIt.I.get<ConversationService>();
  final css = GetIt.I.get<ContactsService>();
  final preferences = await GetIt.I.get<PreferencesService>().getPreferences();
  await cs.createOrUpdateConversation(
    command.jid,
    create: () async {
      // Create
      final contactId = await css.getContactIdForJid(command.jid);
      final newConversation = await cs.addConversationFromData(
        command.title,
        null,
        stringToConversationType(command.conversationType),
        command.avatarUrl,
        command.jid,
        0,
        DateTime.now().millisecondsSinceEpoch,
        true,
        preferences.defaultMuteState,
        preferences.enableOmemoByDefault,
        0,
        contactId,
        await css.getProfilePicturePathForJid(command.jid),
        await css.getContactDisplayName(contactId),
      );

      sendEvent(
        ConversationAddedEvent(
          conversation: newConversation,
        ),
        id: id,
      );
      return newConversation;
    },
    update: (c) async {
      // Update
      if (!c.open) {
        // Re-open the conversation
        final newConversation = await cs.updateConversation(
          c.jid,
          open: true,
          lastChangeTimestamp: DateTime.now().millisecondsSinceEpoch,
        );

        sendEvent(
          ConversationAddedEvent(
            conversation: newConversation,
          ),
          id: id,
        );
        return newConversation;
      }

      sendEvent(
        NoConversationModifiedEvent(),
        id: id,
      );
      return c;
    },
  );
}

Future<void> performSetOpenConversation(
  SetOpenConversationCommand command, {
  dynamic extra,
}) async {
  await GetIt.I.get<XmppService>().setCurrentlyOpenedChatJid(command.jid ?? '');

  // Null just means that the chat has been closed
  // Empty string JID for notes to self
  if (command.jid != null && command.jid != '') {
    await GetIt.I
        .get<NotificationsService>()
        .dismissNotificationsByJid(command.jid!);
  }
}

Future<void> performSendMessage(
  SendMessageCommand command, {
  dynamic extra,
}) async {
  final xs = GetIt.I.get<XmppService>();
  if (command.editSid != null && command.editId != null) {
    assert(
      command.recipients.length == 1,
      'Edits must not be sent to multiple recipients',
    );

    await xs.sendMessageCorrection(
      command.editId!,
      command.body,
      command.editSid!,
      command.recipients.first,
      command.chatState.isNotEmpty
          ? chatStateFromString(command.chatState)
          : null,
    );
    return;
  }

  await xs.sendMessage(
    body: command.body,
    recipients: command.recipients,
    chatState: command.chatState.isNotEmpty
        ? chatStateFromString(command.chatState)
        : null,
    quotedMessage: command.quotedMessage,
    currentConversationJid: command.currentConversationJid,
    commandId: extra as String,
  );
}

Future<void> performBlockJid(BlockJidCommand command, {dynamic extra}) async {
  await GetIt.I.get<BlocklistService>().blockJid(command.jid);
}

Future<void> performUnblockJid(
  UnblockJidCommand command, {
  dynamic extra,
}) async {
  await GetIt.I.get<BlocklistService>().unblockJid(command.jid);
}

Future<void> performUnblockAll(
  UnblockAllCommand command, {
  dynamic extra,
}) async {
  await GetIt.I.get<BlocklistService>().unblockAll();
}

Future<void> performSetCSIState(
  SetCSIStateCommand command, {
  dynamic extra,
}) async {
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

Future<void> performSetPreferences(
  SetPreferencesCommand command, {
  dynamic extra,
}) async {
  final ps = GetIt.I.get<PreferencesService>();
  final oldPrefs = await ps.getPreferences();
  await ps.modifyPreferences((_) => command.preferences);

  // Set the logging mode
  if (!kDebugMode) {
    final enableDebug = command.preferences.debugEnabled;
    Logger.root.level = enableDebug ? Level.ALL : Level.INFO;
  }

  // Scan all contacts if the setting is enabled or disable the database callback
  // if it is disabled.
  final css = GetIt.I.get<ContactsService>();
  if (command.preferences.enableContactIntegration) {
    if (!oldPrefs.enableContactIntegration) {
      css.enableDatabaseListener();
    }

    unawaited(css.scanContacts());
  } else {
    if (oldPrefs.enableContactIntegration) {
      css.disableDatabaseListener();
    }
  }

  // TODO(Unknown): Maybe handle this in StickersService
  // If sticker visibility was changed, apply the settings to the PubSub node
  final pm = GetIt.I
      .get<XmppConnection>()
      .getManagerById<PubSubManager>(pubsubManager)!;
  final ownJid = (await GetIt.I.get<XmppStateService>().getXmppState()).jid!;
  if (command.preferences.isStickersNodePublic &&
      !oldPrefs.isStickersNodePublic) {
    // Set to open
    unawaited(
      pm.configure(
        ownJid,
        stickersXmlns,
        const PubSubPublishOptions(
          accessModel: 'open',
          maxItems: 'max',
        ),
      ),
    );
  } else if (!command.preferences.isStickersNodePublic &&
      oldPrefs.isStickersNodePublic) {
    // Set to presence
    unawaited(
      pm.configure(
        ownJid,
        stickersXmlns,
        const PubSubPublishOptions(
          accessModel: 'presence',
          maxItems: 'max',
        ),
      ),
    );
  }

  // Set the locale
  final locale = command.preferences.languageLocaleCode == 'default'
      ? GetIt.I.get<LanguageService>().defaultLocale
      : command.preferences.languageLocaleCode;
  LocaleSettings.setLocaleRaw(locale);
  GetIt.I.get<XmppService>().setNotificationText(
        await GetIt.I.get<XmppConnection>().getConnectionState(),
      );
}

Future<void> performAddContact(
  AddContactCommand command, {
  dynamic extra,
}) async {
  final id = extra as String;

  final jid = command.jid;
  final roster = GetIt.I.get<RosterService>();
  final inRoster = await roster.isInRoster(jid);
  final cs = GetIt.I.get<ConversationService>();

  await cs.createOrUpdateConversation(
    jid,
    create: () async {
      // Create
      final css = GetIt.I.get<ContactsService>();
      final contactId = await css.getContactIdForJid(jid);
      final prefs = await GetIt.I.get<PreferencesService>().getPreferences();
      final newConversation = await cs.addConversationFromData(
        jid.split('@')[0],
        null,
        ConversationType.chat,
        '',
        jid,
        0,
        DateTime.now().millisecondsSinceEpoch,
        true,
        prefs.defaultMuteState,
        prefs.enableOmemoByDefault,
        0,
        contactId,
        await css.getProfilePicturePathForJid(jid),
        await css.getContactDisplayName(contactId),
      );

      sendEvent(
        AddContactResultEvent(conversation: newConversation, added: !inRoster),
        id: id,
      );

      return newConversation;
    },
    update: (c) async {
      final newConversation = await cs.updateConversation(
        jid,
        open: true,
        lastChangeTimestamp: DateTime.now().millisecondsSinceEpoch,
      );

      sendEvent(
        AddContactResultEvent(conversation: newConversation, added: !inRoster),
        id: id,
      );

      return newConversation;
    },
  );

  // Manage subscription requests
  final srs = GetIt.I.get<SubscriptionRequestService>();
  final hasSubscriptionRequest = await srs.hasPendingSubscriptionRequest(jid);
  if (hasSubscriptionRequest) {
    await srs.acceptSubscriptionRequest(jid);
  }

  // Add to roster, if needed
  final item = await roster.getRosterItemByJid(jid);
  if (item != null) {
    if (item.subscription != 'from' && item.subscription != 'both') {
      GetIt.I.get<Logger>().finest(
            'Roster item already exists with no presence subscription from them. Sending subscription request',
          );
      srs.sendSubscriptionRequest(jid);
    }
  } else {
    await roster.addToRosterWrapper('', '', jid, jid.split('@')[0]);
  }

  // Try to figure out an avatar
  // TODO(Unknown): Don't do that here. Do it more intelligently.
  await GetIt.I.get<AvatarService>().subscribeJid(jid);
  await GetIt.I.get<AvatarService>().fetchAndUpdateAvatarForJid(jid, '');
}

Future<void> performRemoveContact(
  RemoveContactCommand command, {
  dynamic extra,
}) async {
  final rs = GetIt.I.get<RosterService>();
  final cs = GetIt.I.get<ConversationService>();

  // Remove from roster
  await rs.removeFromRosterWrapper(command.jid);

  // Update the conversation
  final conversation = await cs.getConversationByJid(command.jid);
  if (conversation != null) {
    sendEvent(
      ConversationUpdatedEvent(
        conversation: conversation.copyWith(
          inRoster: false,
        ),
      ),
    );
  }
}

Future<void> performRequestDownload(
  RequestDownloadCommand command, {
  dynamic extra,
}) async {
  final ms = GetIt.I.get<MessageService>();
  final srv = GetIt.I.get<HttpFileTransferService>();

  final message = await ms.updateMessage(
    command.message.id,
    isDownloading: true,
  );
  sendEvent(MessageUpdatedEvent(message: message));

  final fileMetadata = command.message.fileMetadata!;
  final metadata = await peekFile(fileMetadata.sourceUrls!.first);

  // TODO(Unknown): Maybe deduplicate with the code in the xmpp service
  // NOTE: This either works by returing "jpg" for ".../hallo.jpg" or fails
  //       for ".../aaaaaaaaa", in which case we would've failed anyways.
  final ext = fileMetadata.sourceUrls!.first.split('.').last;
  final mimeGuess = metadata.mime ?? guessMimeTypeFromExtension(ext);

  await srv.downloadFile(
    FileDownloadJob(
      MediaFileLocation(
        fileMetadata.sourceUrls!,
        fileMetadata.filename,
        fileMetadata.encryptionScheme,
        fileMetadata.encryptionKey != null
            ? base64Decode(fileMetadata.encryptionKey!)
            : null,
        fileMetadata.encryptionIv != null
            ? base64Decode(fileMetadata.encryptionIv!)
            : null,
        fileMetadata.plaintextHashes,
        fileMetadata.ciphertextHashes,
        null,
      ),
      message.id,
      message.fileMetadata!.id,
      message.conversationJid,
      mimeGuess,
    ),
  );
}

Future<void> performSetAvatar(SetAvatarCommand command, {dynamic extra}) async {
  await GetIt.I.get<XmppStateService>().modifyXmppState(
        (state) => state.copyWith(
          avatarUrl: command.path,
          avatarHash: command.hash,
        ),
      );
  await GetIt.I.get<AvatarService>().publishAvatar(command.path, command.hash);
}

Future<void> performSetShareOnlineStatus(
  SetShareOnlineStatusCommand command, {
  dynamic extra,
}) async {
  final rs = GetIt.I.get<RosterService>();
  final srs = GetIt.I.get<SubscriptionRequestService>();
  final item = await rs.getRosterItemByJid(command.jid);

  // TODO(Unknown): Maybe log
  if (item == null) return;

  if (command.share) {
    if (item.ask == 'subscribe') {
      await srs.acceptSubscriptionRequest(command.jid);
    } else {
      srs.sendSubscriptionRequest(command.jid);
    }
  } else {
    if (item.ask == 'subscribe') {
      await srs.rejectSubscriptionRequest(command.jid);
    } else {
      srs.sendUnsubscriptionRequest(command.jid);
    }
  }
}

Future<void> performCloseConversation(
  CloseConversationCommand command, {
  dynamic extra,
}) async {
  final cs = GetIt.I.get<ConversationService>();

  await cs.createOrUpdateConversation(
    command.jid,
    update: (c) async {
      return cs.updateConversation(
        command.jid,
        open: false,
      );
    },
  );

  sendEvent(
    CloseConversationEvent(),
    id: extra as String,
  );
}

Future<void> performSendChatState(
  SendChatStateCommand command, {
  dynamic extra,
}) async {
  final prefs = await GetIt.I.get<PreferencesService>().getPreferences();

  // Only send chat states if the users wants to send them
  if (!prefs.sendChatMarkers) return;

  final conn = GetIt.I.get<XmppConnection>();

  if (command.jid != '') {
    conn
        .getManagerById<ChatStateManager>(chatStateManager)!
        .sendChatState(chatStateFromString(command.state), command.jid);
  }
}

Future<void> performGetFeatures(
  GetFeaturesCommand command, {
  dynamic extra,
}) async {
  final id = extra as String;

  final conn = GetIt.I.get<XmppConnection>();
  final sm = conn.getNegotiatorById<StreamManagementNegotiator>(
    streamManagementNegotiator,
  )!;
  final csi = conn.getNegotiatorById<CSINegotiator>(csiNegotiator)!;
  final httpFileUpload =
      conn.getManagerById<HttpFileUploadManager>(httpFileUploadManager)!;
  final userBlocking = conn.getManagerById<BlockingManager>(blockingManager)!;
  final carbons = conn.getManagerById<CarbonsManager>(carbonsManager)!;
  sendEvent(
    GetFeaturesEvent(
      supportsStreamManagement: sm.isSupported,
      supportsCsi: csi.isSupported,
      supportsHttpFileUpload: await httpFileUpload.isSupported(),
      supportsUserBlocking: await userBlocking.isSupported(),
      supportsCarbons: await carbons.isSupported(),
    ),
    id: id,
  );
}

Future<void> performSignOut(SignOutCommand command, {dynamic extra}) async {
  final id = extra as String;

  final conn = GetIt.I.get<XmppConnection>();
  final xss = GetIt.I.get<XmppStateService>();
  unawaited(conn.disconnect());
  await xss.modifyXmppState((state) => XmppState());

  sendEvent(
    SignedOutEvent(),
    id: id,
  );
}

Future<void> performSendFiles(SendFilesCommand command, {dynamic extra}) async {
  await GetIt.I.get<XmppService>().sendFiles(command.paths, command.recipients);
}

Future<void> performSetMuteState(
  SetConversationMuteStatusCommand command, {
  dynamic extra,
}) async {
  final cs = GetIt.I.get<ConversationService>();

  final conversation = await cs.createOrUpdateConversation(
    command.jid,
    update: (c) async {
      return cs.updateConversation(
        command.jid,
        muted: command.muted,
      );
    },
  );

  if (conversation != null) {
    sendEvent(ConversationUpdatedEvent(conversation: conversation));
  }
}

Future<void> performGetOmemoFingerprints(
  GetConversationOmemoFingerprintsCommand command, {
  dynamic extra,
}) async {
  final id = extra as String;

  final omemo = GetIt.I.get<OmemoService>();
  sendEvent(
    GetConversationOmemoFingerprintsResult(
      fingerprints: await omemo.getOmemoKeysForJid(command.jid),
    ),
    id: id,
  );
}

Future<void> performEnableOmemoKey(
  SetOmemoDeviceEnabledCommand command, {
  dynamic extra,
}) async {
  final id = extra as String;

  final omemo = GetIt.I.get<OmemoService>();
  await omemo.setOmemoKeyEnabled(
    command.jid,
    command.deviceId,
    command.enabled,
  );

  await performGetOmemoFingerprints(
    GetConversationOmemoFingerprintsCommand(jid: command.jid),
    extra: id,
  );
}

Future<void> performRecreateSessions(
  RecreateSessionsCommand command, {
  dynamic extra,
}) async {
  await GetIt.I.get<OmemoService>().removeAllSessions(command.jid);

  final conn = GetIt.I.get<XmppConnection>();
  await conn.getManagerById<BaseOmemoManager>(omemoManager)!.sendOmemoHeartbeat(
        command.jid,
      );
}

Future<void> performSetOmemoEnabled(
  SetOmemoEnabledCommand command, {
  dynamic extra,
}) async {
  final cs = GetIt.I.get<ConversationService>();

  await cs.createOrUpdateConversation(
    command.jid,
    update: (c) async {
      return cs.updateConversation(
        command.jid,
        encrypted: command.enabled,
      );
    },
  );
}

Future<void> performGetOwnOmemoFingerprints(
  GetOwnOmemoFingerprintsCommand command, {
  dynamic extra,
}) async {
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

Future<void> performRemoveOwnDevice(
  RemoveOwnDeviceCommand command, {
  dynamic extra,
}) async {
  await GetIt.I
      .get<XmppConnection>()
      .getManagerById<BaseOmemoManager>(omemoManager)!
      .deleteDevice(command.deviceId);
}

Future<void> performRegenerateOwnDevice(
  RegenerateOwnDeviceCommand command, {
  dynamic extra,
}) async {
  final id = extra as String;
  final jid =
      GetIt.I.get<XmppConnection>().connectionSettings.jid.toBare().toString();
  final device = await GetIt.I.get<OmemoService>().regenerateDevice(jid);

  sendEvent(
    RegenerateOwnDeviceResult(device: device),
    id: id,
  );
}

Future<void> performMessageRetraction(
  RetractMessageCommentCommand command, {
  dynamic extra,
}) async {
  await GetIt.I.get<MessageService>().retractMessage(
        command.conversationJid,
        command.originId,
        '',
        true,
      );
  if (command.conversationJid != '') {
    (GetIt.I
            .get<XmppConnection>()
            .getManagerById<MessageManager>(messageManager)!)
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
}

Future<void> performMarkConversationAsRead(
  MarkConversationAsReadCommand command, {
  dynamic extra,
}) async {
  final cs = GetIt.I.get<ConversationService>();

  // Update the database
  final conversation = await cs.createOrUpdateConversation(
    command.conversationJid,
    update: (c) async {
      return cs.updateConversation(
        command.conversationJid,
        unreadCounter: 0,
      );
    },
  );
  if (conversation != null) {
    sendEvent(ConversationUpdatedEvent(conversation: conversation));

    if (conversation.lastMessage != null) {
      await GetIt.I.get<XmppService>().sendReadMarker(
            command.conversationJid,
            conversation.lastMessage!.sid,
          );
    }
  }

  // Dismiss notifications for that chat
  await GetIt.I.get<NotificationsService>().dismissNotificationsByJid(
        command.conversationJid,
      );
}

Future<void> performMarkMessageAsRead(
  MarkMessageAsReadCommand command, {
  dynamic extra,
}) async {
  final cs = GetIt.I.get<ConversationService>();

  final conversation = await cs.createOrUpdateConversation(
    command.conversationJid,
    update: (c) async {
      return cs.updateConversation(
        command.conversationJid,
        unreadCounter: command.newUnreadCounter,
      );
    },
  );

  if (conversation != null) {
    sendEvent(ConversationUpdatedEvent(conversation: conversation));

    await GetIt.I.get<XmppService>().sendReadMarker(
          command.conversationJid,
          command.sid,
        );
  }
}

Future<void> performAddMessageReaction(
  AddReactionToMessageCommand command, {
  dynamic extra,
}) async {
  final ms = GetIt.I.get<MessageService>();
  final conn = GetIt.I.get<XmppConnection>();
  final msg =
      await ms.getMessageById(command.messageId, command.conversationJid);
  assert(msg != null, 'The message must be found');

  // Update the state
  final reactions = List<Reaction>.from(msg!.reactions);
  final i = reactions.indexWhere((r) => r.emoji == command.emoji);
  if (i == -1) {
    reactions.add(Reaction([], command.emoji, true));
  } else {
    reactions[i] = reactions[i].copyWith(reactedBySelf: true);
  }
  await ms.updateMessage(msg.id, reactions: reactions);

  // Collect all our reactions
  final ownReactions =
      reactions.where((r) => r.reactedBySelf).map((r) => r.emoji).toList();

  if (command.conversationJid != '') {
    // Send the reaction
    conn.getManagerById<MessageManager>(messageManager)!.sendMessage(
          MessageDetails(
            to: command.conversationJid,
            messageReactions: MessageReactions(
              msg.originId ?? msg.sid,
              ownReactions,
            ),
            requestChatMarkers: false,
            messageProcessingHints:
                !msg.containsNoStore ? [MessageProcessingHint.store] : null,
          ),
        );
  }
}

Future<void> performRemoveMessageReaction(
  RemoveReactionFromMessageCommand command, {
  dynamic extra,
}) async {
  final ms = GetIt.I.get<MessageService>();
  final conn = GetIt.I.get<XmppConnection>();
  final msg =
      await ms.getMessageById(command.messageId, command.conversationJid);
  assert(msg != null, 'The message must be found');

  // Update the state
  final reactions = List<Reaction>.from(msg!.reactions);
  final i = reactions.indexWhere((r) => r.emoji == command.emoji);
  assert(i >= -1, 'The reaction must be found');
  if (reactions[i].senders.isEmpty) {
    reactions.removeAt(i);
  } else {
    reactions[i] = reactions[i].copyWith(reactedBySelf: false);
  }
  await ms.updateMessage(msg.id, reactions: reactions);

  // Collect all our reactions
  final ownReactions =
      reactions.where((r) => r.reactedBySelf).map((r) => r.emoji).toList();

  if (command.conversationJid != '') {
    // Send the reaction
    conn.getManagerById<MessageManager>(messageManager)!.sendMessage(
          MessageDetails(
            to: command.conversationJid,
            messageReactions: MessageReactions(
              msg.originId ?? msg.sid,
              ownReactions,
            ),
            requestChatMarkers: false,
            messageProcessingHints:
                !msg.containsNoStore ? [MessageProcessingHint.store] : null,
          ),
        );
  }
}

Future<void> performMarkDeviceVerified(
  MarkOmemoDeviceAsVerifiedCommand command, {
  dynamic extra,
}) async {
  await GetIt.I.get<OmemoService>().verifyDevice(
        command.deviceId,
        command.jid,
      );
}

Future<void> performImportStickerPack(
  ImportStickerPackCommand command, {
  dynamic extra,
}) async {
  final id = extra as String;
  final result =
      await GetIt.I.get<StickersService>().importFromFile(command.path);
  if (result != null) {
    sendEvent(
      StickerPackImportSuccessEvent(
        stickerPack: result,
      ),
      id: id,
    );
  } else {
    sendEvent(
      StickerPackImportFailureEvent(),
      id: id,
    );
  }
}

Future<void> performSendSticker(
  SendStickerCommand command, {
  dynamic extra,
}) async {
  await GetIt.I.get<XmppService>().sendMessage(
        body: command.sticker.desc,
        recipients: [command.recipient],
        sticker: command.sticker,
        currentConversationJid: command.recipient,
      );
}

Future<void> performRemoveStickerPack(
  RemoveStickerPackCommand command, {
  dynamic extra,
}) async {
  await GetIt.I.get<StickersService>().removeStickerPack(
        command.stickerPackId,
      );
}

Future<void> performFetchStickerPack(
  FetchStickerPackCommand command, {
  dynamic extra,
}) async {
  final id = extra as String;

  final result = await GetIt.I
      .get<XmppConnection>()
      .getManagerById<StickersManager>(stickersManager)!
      .fetchStickerPack(JID.fromString(command.jid), command.stickerPackId);

  if (result.isType<PubSubError>()) {
    sendEvent(
      FetchStickerPackFailureResult(),
      id: id,
    );
  } else {
    final stickerPack = result.get<StickerPack>();
    sendEvent(
      FetchStickerPackSuccessResult(
        stickerPack: sticker_pack.StickerPack(
          command.stickerPackId,
          stickerPack.name,
          stickerPack.summary,
          stickerPack.stickers
              .map(
                (s) => sticker.Sticker(
                  '',
                  command.stickerPackId,
                  s.metadata.desc!,
                  s.suggests,
                  FileMetadata(
                    '',
                    null,
                    s.sources
                        .whereType<StatelessFileSharingUrlSource>()
                        .map((src) => src.url)
                        .toList(),
                    s.metadata.mediaType,
                    s.metadata.size,
                    // TODO(Unknown): One day
                    null,
                    null,
                    s.metadata.width,
                    s.metadata.height,
                    s.metadata.hashes,
                    null,
                    null,
                    null,
                    null,
                    s.metadata.name ?? '',
                  ),
                ),
              )
              .toList(),
          stickerPack.hashAlgorithm.toName(),
          stickerPack.hashValue,
          stickerPack.restricted,
          false,
        ),
      ),
      id: id,
    );
  }
}

Future<void> performStickerPackInstall(
  InstallStickerPackCommand command, {
  dynamic extra,
}) async {
  final id = extra as String;

  final ss = GetIt.I.get<StickersService>();
  final pack = await ss.installFromPubSub(command.stickerPack);
  if (pack != null) {
    sendEvent(
      StickerPackInstallSuccessEvent(
        stickerPack: pack,
      ),
      id: id,
    );
  } else {
    sendEvent(
      StickerPackInstallFailureEvent(),
      id: id,
    );
  }
}

Future<void> performGetBlocklist(
  GetBlocklistCommand command, {
  dynamic extra,
}) async {
  final id = extra as String;

  final result = await GetIt.I.get<BlocklistService>().getBlocklist();
  sendEvent(
    GetBlocklistResultEvent(
      entries: result,
    ),
    id: id,
  );
}

Future<void> performGetPagedMessages(
  GetPagedMessagesCommand command, {
  dynamic extra,
}) async {
  final id = extra as String;

  final result = await GetIt.I.get<MessageService>().getPaginatedMessagesForJid(
        command.conversationJid,
        command.olderThan,
        command.timestamp,
      );

  sendEvent(
    PagedMessagesResultEvent(
      messages: result,
    ),
    id: id,
  );
}

Future<void> performGetPagedSharedMedia(
  GetPagedSharedMediaCommand command, {
  dynamic extra,
}) async {
  final id = extra as String;

  final result =
      await GetIt.I.get<DatabaseService>().getPaginatedSharedMediaForJid(
            command.conversationJid,
            command.olderThan,
            command.timestamp,
          );

  sendEvent(
    PagedSharedMediaResultEvent(
      media: result,
    ),
    id: id,
  );
}
