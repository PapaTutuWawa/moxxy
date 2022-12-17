import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:mime/mime.dart';
import 'package:moxlib/moxlib.dart';
import 'package:moxplatform_platform_interface/moxplatform_platform_interface.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/service/avatars.dart';
import 'package:moxxyv2/service/blocking.dart';
import 'package:moxxyv2/service/connectivity.dart';
import 'package:moxxyv2/service/connectivity_watcher.dart';
import 'package:moxxyv2/service/contacts.dart';
import 'package:moxxyv2/service/conversation.dart';
import 'package:moxxyv2/service/database/database.dart';
import 'package:moxxyv2/service/helpers.dart';
import 'package:moxxyv2/service/httpfiletransfer/helpers.dart';
import 'package:moxxyv2/service/httpfiletransfer/httpfiletransfer.dart';
import 'package:moxxyv2/service/httpfiletransfer/jobs.dart';
import 'package:moxxyv2/service/httpfiletransfer/location.dart';
import 'package:moxxyv2/service/message.dart';
import 'package:moxxyv2/service/notifications.dart';
import 'package:moxxyv2/service/omemo/omemo.dart';
import 'package:moxxyv2/service/preferences.dart';
import 'package:moxxyv2/service/roster.dart';
import 'package:moxxyv2/service/service.dart';
import 'package:moxxyv2/service/state.dart';
import 'package:moxxyv2/service/stickers.dart';
import 'package:moxxyv2/shared/error_types.dart';
import 'package:moxxyv2/shared/eventhandler.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/shared/models/media.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/shared/models/reaction.dart';
import 'package:moxxyv2/shared/models/sticker.dart' as sticker;
import 'package:path/path.dart' as pathlib;
import 'package:permission_handler/permission_handler.dart';

class XmppService {
  XmppService() :
    _currentlyOpenedChatJid = '',
    _xmppConnectionSubscription = null,
    _state = null,
    _eventHandler = EventHandler(),
    _appOpen = true,
    _loginTriggeredFromUI = false,
    _log = Logger('XmppService') {
      _eventHandler.addMatchers([
        EventTypeMatcher<ConnectionStateChangedEvent>(_onConnectionStateChanged),
        EventTypeMatcher<ResourceBindingSuccessEvent>(_onResourceBindingSuccess),
        EventTypeMatcher<SubscriptionRequestReceivedEvent>(_onSubscriptionRequestReceived),
        EventTypeMatcher<DeliveryReceiptReceivedEvent>(_onDeliveryReceiptReceived),
        EventTypeMatcher<ChatMarkerEvent>(_onChatMarker),
        EventTypeMatcher<RosterPushEvent>(_onRosterPush),
        EventTypeMatcher<AvatarUpdatedEvent>(_onAvatarUpdated),
        EventTypeMatcher<StanzaAckedEvent>(_onStanzaAcked),
        EventTypeMatcher<MessageEvent>(_onMessage),
        EventTypeMatcher<BlocklistBlockPushEvent>(_onBlocklistBlockPush),
        EventTypeMatcher<BlocklistUnblockPushEvent>(_onBlocklistUnblockPush),
        EventTypeMatcher<BlocklistUnblockAllPushEvent>(_onBlocklistUnblockAllPush),
        EventTypeMatcher<StanzaSendingCancelledEvent>(_onStanzaSendingCancelled),
      ]);
    }
  final Logger _log;
  final EventHandler _eventHandler;
  bool _loginTriggeredFromUI;
  bool _appOpen;
  String _currentlyOpenedChatJid;
  StreamSubscription<dynamic>? _xmppConnectionSubscription;
  XmppState? _state;

  Future<XmppState> getXmppState() async {
    if (_state != null) return _state!;

    _state = await GetIt.I.get<DatabaseService>().getXmppState();
    return _state!;
  }

  /// A wrapper to modify the [XmppState] and commit it.
  Future<void> modifyXmppState(XmppState Function(XmppState) func) async {
    _state = func(_state!);
    await GetIt.I.get<DatabaseService>().saveXmppState(_state!);
  }

  /// Stores whether the app is open or not. Useful for notifications.
  void setAppState(bool open) {
    _appOpen = open;
  }
  
  Future<ConnectionSettings?> getConnectionSettings() async {
    final state = await getXmppState();

    if (state.jid == null || state.password == null) {
      return null;
    }

    return ConnectionSettings(
      jid: JID.fromString(state.jid!),
      password: state.password!,
      useDirectTLS: true,
      allowPlainAuth: true,
    );
  }

  /// Marks the conversation with jid [jid] as open and resets its unread counter if it is
  /// greater than 0.
  Future<void> setCurrentlyOpenedChatJid(String jid) async {
    final cs = GetIt.I.get<ConversationService>();

    _currentlyOpenedChatJid = jid;
    final conversation = await cs.getConversationByJid(jid);

    if (conversation != null && conversation.unreadCounter > 0) {
      final newConversation = await cs.updateConversation(
        conversation.id,
        unreadCounter: 0,
      );

      sendEvent(
        ConversationUpdatedEvent(conversation: newConversation),
      );
    }
  }

  /// Returns the JID of the chat that is currently opened. Null, if none is open.
  String? getCurrentlyOpenedChatJid() => _currentlyOpenedChatJid;

  /// Sends a message correction to [recipient] regarding the message with stanza id
  /// [oldId]. The old message's body gets corrected to [newBody]. [id] is the message's
  /// database id. [chatState] can be optionally specified to also include a chat state
  /// in the message.
  ///
  /// This function handles updating the message and optionally the corresponding
  /// conversation.
  Future<void> sendMessageCorrection(int id, String newBody, String oldId, String recipient, ChatState? chatState) async {
    final ms = GetIt.I.get<MessageService>();
    final cs = GetIt.I.get<ConversationService>();
    final conn = GetIt.I.get<XmppConnection>();
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // Update the database
    final msg = await ms.updateMessage(
      id,
      isEdited: true,
      body: newBody,
    );
    sendEvent(MessageUpdatedEvent(message: msg));

    final conv = await cs.getConversationByJid(msg.conversationJid);
    if (conv != null && conv.lastMessage?.id == id) {
      final newConv = await cs.updateConversation(
        conv.id,
        lastChangeTimestamp: timestamp,
        lastMessage: msg,
      );
      cs.setConversation(newConv);
      sendEvent(ConversationUpdatedEvent(conversation: newConv));
    }
    
    // Send the correction
    conn.getManagerById<MessageManager>(messageManager)!.sendMessage(
      MessageDetails(
        to: recipient,
        body: newBody,
        lastMessageCorrectionId: oldId,
        chatState: chatState,
      ),
    );
  }
  
  /// Sends a message to JIDs in [recipients] with the body of [body].
  Future<void> sendMessage({
      required String body,
      required List<String> recipients,
      Message? quotedMessage,
      String? commandId,
      ChatState? chatState,
      sticker.Sticker? sticker,
  }) async {
    final ms = GetIt.I.get<MessageService>();
    final cs = GetIt.I.get<ConversationService>();
    final conn = GetIt.I.get<XmppConnection>();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    
    for (final recipient in recipients) {
      final sid = conn.generateId();
      final originId = conn.generateId();
      final conversation = await cs.getConversationByJid(recipient);
      final message = await ms.addMessageFromData(
        body,
        timestamp,
        conn.getConnectionSettings().jid.toString(),
        recipient,
        sticker != null,
        sid,
        false,
        conversation!.encrypted,
        // TODO(Unknown): Maybe make this depend on some setting
        false,
        originId: originId,
        quoteId: quotedMessage?.sid,
        stickerPackId: sticker?.stickerPackId,
        stickerId: sticker?.id,
      );
      final newConversation = await cs.updateConversation(
        conversation.id,
        lastMessage: message,
        lastChangeTimestamp: timestamp,
      );

      // Using the same ID should be fine.
      sendEvent(
        MessageAddedEvent(message: message),
        id: commandId,
      );
      
      conn.getManagerById<MessageManager>(messageManager)!.sendMessage(
        MessageDetails(
          to: recipient,
          body: body,
          requestDeliveryReceipt: true,
          id: sid,
          originId: originId,
          quoteBody: createFallbackBodyForQuotedMessage(quotedMessage),
          quoteFrom: quotedMessage?.sender,
          quoteId: quotedMessage?.sid,
          chatState: chatState,
          shouldEncrypt: newConversation.encrypted,
          stickerPackId: sticker?.stickerPackId,
          sfs: sticker == null ?
            null :
            StatelessFileSharingData(
              FileMetadataData(
                mediaType: sticker.mediaType,
                width: sticker.width,
                height: sticker.height,
                desc: sticker.desc,
                size: sticker.size,
                thumbnails: [],
                hashes: sticker.hashes,
              ),
              sticker.urlSources
                .map((s) => StatelessFileSharingUrlSource(s))
                .toList(),
            ),
        ),
      );

      sendEvent(
        ConversationUpdatedEvent(conversation: newConversation),
      );
    }
  }

  MediaFileLocation? _getMessageSrcUrl(MessageEvent event) {
    if (event.sfs != null) {
      final source = firstWhereOrNull(
        event.sfs!.sources,
        (StatelessFileSharingSource source) {
          return source is StatelessFileSharingUrlSource || source is StatelessFileSharingEncryptedSource;
        },
      );

      final name = event.sfs?.metadata.name;
      if (source is StatelessFileSharingUrlSource) {
        return MediaFileLocation(
          source.url,
          name != null ?
            escapeFilename(name) :
            filenameFromUrl(source.url),
          null,
          null,
          null,
          event.sfs?.metadata.hashes,
          null,
        );
      } else {
        final esource = source! as StatelessFileSharingEncryptedSource;
        return MediaFileLocation(
          esource.source.url,
          name != null ?
            escapeFilename(name) :
            filenameFromUrl(esource.source.url),
          esource.encryption.toNamespace(),
          esource.key,
          esource.iv,
          event.sfs?.metadata.hashes,
          esource.hashes,
        );
      }
    } else if (event.oob != null) {
      return MediaFileLocation(
        event.oob!.url!,
        filenameFromUrl(event.oob!.url!),
        null,
        null,
        null,
        null,
        null,
      );
    }

    return null;
  }

  Future<void> _acknowledgeMessage(MessageEvent event) async {
    final result = await GetIt.I.get<XmppConnection>().getDiscoManager().discoInfoQuery(event.fromJid.toString());
    if (result.isType<DiscoError>()) return;

    final info = result.get<DiscoInfo>();
    if (event.isMarkable && info.features.contains(chatMarkersXmlns)) {
      unawaited(
        GetIt.I.get<XmppConnection>().sendStanza(
          Stanza.message(
            to: event.fromJid.toBare().toString(),
            type: event.type,
            children: [
              makeChatMarker('received', event.stanzaId.originId ?? event.sid)
            ],
          ),
        ),
      );
    } else if (event.deliveryReceiptRequested && info.features.contains(deliveryXmlns)) {
      unawaited(
        GetIt.I.get<XmppConnection>().sendStanza(
          Stanza.message(
            to: event.fromJid.toBare().toString(),
            type: event.type,
            children: [
              makeMessageDeliveryResponse(event.stanzaId.originId ?? event.sid)
            ],
          ),
        ),
      );
    }
  }

  /// Send a read marker to [to] in order to mark the message with stanza id [sid]
  /// as read. If sending chat markers is disabled in the preferences, then this
  /// function will do nothing.
  Future<void> sendReadMarker(String to, String sid) async {
    final prefs = await GetIt.I.get<PreferencesService>().getPreferences();
    if (!prefs.sendChatMarkers) return;

    unawaited(
      GetIt.I.get<XmppConnection>().sendStanza(
        Stanza.message(
          to: to,
          type: 'chat',
          children: [
            makeChatMarker('displayed', sid),
          ],
        ),
      ),
    );
  }

  /// Returns true if we are allowed to automatically download a file
  Future<bool> _automaticFileDownloadAllowed() async {
    final prefs = await GetIt.I.get<PreferencesService>().getPreferences();

    final currentConnection = GetIt.I.get<ConnectivityService>().currentState;
    return prefs.autoDownloadWifi && currentConnection == ConnectivityResult.wifi
      || prefs.autoDownloadMobile && currentConnection == ConnectivityResult.mobile;
  }
 
  void installEventHandlers() {
    _xmppConnectionSubscription?.cancel();
    _xmppConnectionSubscription = GetIt.I.get<XmppConnection>().asBroadcastStream().listen(_eventHandler.run);
  }

  Future<void> connect(ConnectionSettings settings, bool triggeredFromUI) async {
    final lastResource = (await getXmppState()).resource;

    _loginTriggeredFromUI = triggeredFromUI;
    GetIt.I.get<XmppConnection>().setConnectionSettings(settings);
    unawaited(GetIt.I.get<XmppConnection>().connect(lastResource: lastResource));
    installEventHandlers();
  }

  Future<XmppConnectionResult> connectAwaitable(ConnectionSettings settings, bool triggeredFromUI) async {
    final lastResource = (await getXmppState()).resource;

    _loginTriggeredFromUI = triggeredFromUI;
    GetIt.I.get<XmppConnection>().setConnectionSettings(settings);
    installEventHandlers();
    return GetIt.I.get<XmppConnection>().connectAwaitable(lastResource: lastResource);
  }

  /// Wrapper function for creating shared media entries for the given paths.
  /// [messages] is the mapping of "File path -> Recipient -> Message" required for
  /// setting the single shared medium's message Id attribute.
  /// [paths] is the list of paths to create shared media entries for.
  /// [recipient] is the bare string JID that the messages will be sent to.
  /// [conversationId] is the database id of the conversation these shared media entries
  /// belong to.
  Future<List<SharedMedium>> _createSharedMedia(Map<String, Map<String, Message>> messages, List<String> paths, String recipient, int conversationId) async {
    final sharedMedia = List<SharedMedium>.empty(growable: true);
    for (final path in paths) {
      sharedMedia.add(
        await GetIt.I.get<DatabaseService>().addSharedMediumFromData(
          path,
          DateTime.now().millisecondsSinceEpoch,
          conversationId,
          messages[path]![recipient]!.id,
          mime: lookupMimeType(path),
        ),
      );
    }
    return sharedMedia;
  }
  
  Future<void> sendFiles(List<String> paths, List<String> recipients) async {
    // Create a new message
    final ms = GetIt.I.get<MessageService>();
    final cs = GetIt.I.get<ConversationService>();
    final css = GetIt.I.get<ContactsService>();
    final prefs = await GetIt.I.get<PreferencesService>().getPreferences();

    // Path -> Recipient -> Message
    final messages = <String, Map<String, Message>>{};
    // Path -> Thumbnails
    final thumbnails = <String, List<Thumbnail>>{};
    // Path -> Dimensions
    final dimensions = <String, Size>{};
    // Recipient -> Should encrypt
    final encrypt = <String, bool>{};
    // Recipient -> Last message Id
    final lastMessages = <String, Message>{};

    // Create the messages and shared media entries
    final conn = GetIt.I.get<XmppConnection>();
    for (final path in paths) {
      final pathMime = lookupMimeType(path);

      for (final recipient in recipients) {
        final conversation = await cs.getConversationByJid(recipient);
        encrypt[recipient] = conversation?.encrypted ?? prefs.enableOmemoByDefault;

        // TODO(Unknown): Do the same for videos
        if (pathMime != null && pathMime.startsWith('image/')) {
          final imageSize = await getImageSizeFromPath(path);
          if (imageSize != null) {
            dimensions[path] = Size(
              imageSize.width,
              imageSize.height,
            );
          } else {
            _log.warning('Failed to get image dimensions for $path');
          }
        }

        final msg = await ms.addMessageFromData(
          '',
          DateTime.now().millisecondsSinceEpoch, 
          conn.getConnectionSettings().jid.toString(),
          recipient,
          true,
          conn.generateId(),
          false,
          encrypt[recipient]!,
          // TODO(Unknown): Maybe make this depend on some setting
          false,
          mediaUrl: path,
          mediaType: pathMime,
          originId: conn.generateId(),
          mediaWidth: dimensions[path]?.width.toInt(),
          mediaHeight: dimensions[path]?.height.toInt(),
          filename: pathlib.basename(path),
          isUploading: true,
        );
        if (messages.containsKey(path)) {
          messages[path]![recipient] = msg;
        } else {
          messages[path] = { recipient: msg };
        }

        if (path == paths.last) {
          lastMessages[recipient] = msg;
        }

        sendEvent(MessageAddedEvent(message: msg));
      }
    }

    // Create the shared media entries
    // Recipient -> [Shared Medium]
    final sharedMediaMap = <String, List<SharedMedium>>{};
    final rs = GetIt.I.get<RosterService>();
    for (final recipient in recipients) {
      final conversation = await cs.getConversationByJid(recipient);
      if (conversation != null) {
        // Update conversation
        var updatedConversation = await cs.updateConversation(
          conversation.id,
          lastMessage: lastMessages[recipient],
          lastChangeTimestamp: DateTime.now().millisecondsSinceEpoch,
          open: true,
        );

        sharedMediaMap[recipient] = await _createSharedMedia(messages, paths, recipient, conversation.id);

        updatedConversation = updatedConversation.copyWith(
          sharedMedia: [
            ...sharedMediaMap[recipient]!,
            ...conversation.sharedMedia,
          ],
        );
        cs.setConversation(updatedConversation);
        sendEvent(ConversationUpdatedEvent(conversation: updatedConversation));
      } else {
        // Create conversation
        final rosterItem = await rs.getRosterItemByJid(recipient);
        final contactId = await css.getContactIdForJid(recipient);
        var newConversation = await cs.addConversationFromData(
          // TODO(Unknown): Should we use the JID parser?
          rosterItem?.title ?? recipient.split('@').first,
          lastMessages[recipient],
          rosterItem?.avatarUrl ?? '',
          recipient,
          0,
          DateTime.now().millisecondsSinceEpoch,
          true,
          prefs.defaultMuteState,
          prefs.enableOmemoByDefault,
          contactId,
          await css.getProfilePicturePathForJid(recipient),
          await css.getContactDisplayName(contactId),
        );

        sharedMediaMap[recipient] = await _createSharedMedia(messages, paths, recipient, newConversation.id);
        newConversation = newConversation.copyWith(
          sharedMedia: sharedMediaMap[recipient]!,
        );
        cs.setConversation(newConversation);

        // Notify the UI
        sendEvent(ConversationAddedEvent(conversation: newConversation));
      }
    }

    // Requesting Upload slots and uploading
    final hfts = GetIt.I.get<HttpFileTransferService>();
    for (final path in paths) {
      final pathMime = lookupMimeType(path);

      for (final recipient in recipients) {
        // TODO(PapaTutuWawa): Do this for videos
        // TODO(PapaTutuWawa): Maybe do this in a separate isolate
        if ((pathMime ?? '').startsWith('image/')) {
          // Generate a thumbnail only when we have to
          if (!thumbnails.containsKey(path)) {
            final thumbnail = await generateBlurhashThumbnail(path);
            if (thumbnail != null) {
              thumbnails[path] = [BlurhashThumbnail(thumbnail)];
            } else {
              _log.warning('Failed to generate thumbnail for $path');
            }
          }
        }

        // Send an upload notification
        conn.getManagerById<MessageManager>(messageManager)!.sendMessage(
          MessageDetails(
            to: recipient,
            id: messages[path]![recipient]!.sid,
            fun: FileMetadataData(
              // TODO(Unknown): Maybe add media type specific metadata
              mediaType: lookupMimeType(path),
              name: pathlib.basename(path),
              size: File(path).statSync().size,
              thumbnails: thumbnails[path] ?? [],
            ),
            shouldEncrypt: encrypt[recipient]!,
          ),
        );
      }

      await hfts.uploadFile(
        FileUploadJob(
          recipients,
          path,
          pathMime,
          encrypt,
          messages[path]!,
          thumbnails[path] ?? [],
        ),
      );
    }

    _log.finest('File upload done');
  }

  Future<void> _initializeOmemoService(String jid) async {
    await GetIt.I.get<OmemoService>().initializeIfNeeded(jid);
    final result = await GetIt.I.get<OmemoService>().publishDeviceIfNeeded();
    if (result != null) {
      // Notify the user that we could not publish the Omemo ~identity~ titty
      await GetIt.I.get<NotificationsService>().showWarningNotification(
        'Encryption',
        t.errors.omemo.couldNotPublish,
      );
    }
  }

  /// Sets the permanent notification's title to the corresponding one for the
  /// XmppConnection's state [state].
  void setNotificationText(XmppConnectionState state) {
    switch (state) {
      case XmppConnectionState.connected:
        GetIt.I.get<BackgroundService>().setNotification(
          'Moxxy',
          t.notifications.permanent.ready,
        );
      break;
      case XmppConnectionState.connecting:
        GetIt.I.get<BackgroundService>().setNotification(
          'Moxxy',
          t.notifications.permanent.connecting,
        );
      break;
      case XmppConnectionState.notConnected:
        GetIt.I.get<BackgroundService>().setNotification(
          'Moxxy',
          t.notifications.permanent.disconnect,
        );
      break;
      case XmppConnectionState.error:
        GetIt.I.get<BackgroundService>().setNotification(
          'Moxxy',
          t.notifications.permanent.error,
        );
      break;
    }
  }
  
  Future<void> _onConnectionStateChanged(ConnectionStateChangedEvent event, { dynamic extra }) async {
    setNotificationText(event.state);

    await GetIt.I.get<ConnectivityWatcherService>().onConnectionStateChanged(
      event.before, event.state,
    );
    
    if (event.state == XmppConnectionState.connected) {
      final connection = GetIt.I.get<XmppConnection>();

      // TODO(Unknown): Maybe have something better
      final settings = connection.getConnectionSettings();
      await modifyXmppState((state) => state.copyWith(
          jid: settings.jid.toString(),
          password: settings.password,
      ),);

      _log.finest('Connection connected. Is resumed? ${event.resumed}');
      unawaited(_initializeOmemoService(settings.jid.toString()));

      if (!event.resumed) {
        // Enable carbons
        final carbonsResult = await connection
          .getManagerById<CarbonsManager>(carbonsManager)!
          .enableCarbons();
        if (!carbonsResult) {
          _log.warning('Failed to enable carbons');
        }

        // In section 5 of XEP-0198 it says that a client should not request the roster
        // in case of a stream resumption.
        await GetIt.I.get<RosterService>().requestRoster();

        // TODO(Unknown): Once groupchats come into the equation, this gets trickier
        final roster = await GetIt.I.get<RosterService>().getRoster();
        for (final item in roster) {
          await GetIt.I.get<AvatarService>().fetchAndUpdateAvatarForJid(item.jid, item.avatarHash);
        }

        await GetIt.I.get<BlocklistService>().getBlocklist();
      }
      
      // Make sure we display our own avatar correctly.
      // Note that this only requests the avatar if its hash differs from the locally cached avatar's.
      // TODO(Unknown): Maybe don't do this on mobile Internet
      unawaited(GetIt.I.get<AvatarService>().requestOwnAvatar());
      
      if (_loginTriggeredFromUI) {
        // TODO(Unknown): Trigger another event so the UI can see this aswell
        await modifyXmppState((state) => state.copyWith(
          jid: connection.getConnectionSettings().jid.toString(),
          displayName: connection.getConnectionSettings().jid.local,
          avatarUrl: '',
          avatarHash: '',
        ),);
      }
    }
  }

  Future<void> _onResourceBindingSuccess(ResourceBindingSuccessEvent event, { dynamic extra }) async {
    await modifyXmppState((state) => state.copyWith(
        resource: event.resource,
    ),);
  }

  Future<void> _onSubscriptionRequestReceived(SubscriptionRequestReceivedEvent event, { dynamic extra }) async {
    final prefs = await GetIt.I.get<PreferencesService>().getPreferences();

    if (prefs.autoAcceptSubscriptionRequests) {
      GetIt.I.get<XmppConnection>().getPresenceManager().sendSubscriptionRequestApproval(
        event.from.toBare().toString(),
      );
    }

    if (!prefs.showSubscriptionRequests) return;
    
    final css = GetIt.I.get<ContactsService>();
    final cs = GetIt.I.get<ConversationService>();
    final conversation = await cs.getConversationByJid(event.from.toBare().toString());
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    if (conversation != null && !conversation.open) {
      // TODO(Unknown): Make it configurable if this should happen
      final bare = event.from.toBare().toString();
      final contactId = await css.getContactIdForJid(bare);
      final conv = await cs.addConversationFromData(
        bare.split('@')[0],
        null,
        '', // TODO(Unknown): avatarUrl
        bare,
        0,
        timestamp,
        true,
        prefs.defaultMuteState,
        prefs.enableOmemoByDefault,
        contactId,
        await css.getProfilePicturePathForJid(bare),
        await css.getContactDisplayName(contactId),
      );

      sendEvent(ConversationAddedEvent(conversation: conv));
    }
  }

  Future<void> _onDeliveryReceiptReceived(DeliveryReceiptReceivedEvent event, { dynamic extra }) async {
    _log.finest('Received delivery receipt from ${event.from.toString()}');
    final db = GetIt.I.get<DatabaseService>();
    final ms = GetIt.I.get<MessageService>();
    final cs = GetIt.I.get<ConversationService>();
    final sender = event.from.toBare().toString();
    final dbMsg = await db.getMessageByXmppId(event.id, sender);
    if (dbMsg == null) {
      _log.warning('Did not find the message with id ${event.id} in the database!');
      return;
    }
    
    final msg = await ms.updateMessage(
      dbMsg.id,
      received: true,
    );
    sendEvent(MessageUpdatedEvent(message: msg));

    // Update the conversation
    final conv = await cs.getConversationByJid(sender);
    if (conv != null && conv.lastMessage?.id == msg.id) {
      final newConv = conv.copyWith(lastMessage: msg);
      cs.setConversation(newConv);
      _log.finest('Updating conversation');
      sendEvent(ConversationUpdatedEvent(conversation: newConv));
    }
  }

  Future<void> _onChatMarker(ChatMarkerEvent event, { dynamic extra }) async {
    _log.finest('Chat marker from ${event.from.toString()}');
    if (event.type == 'acknowledged') return;

    final db = GetIt.I.get<DatabaseService>();
    final ms = GetIt.I.get<MessageService>();
    final cs = GetIt.I.get<ConversationService>();
    final sender = event.from.toBare().toString();
    final dbMsg = await db.getMessageByXmppId(event.id, sender);
    if (dbMsg == null) {
      _log.warning('Did not find the message in the database!');
      return;
    }
    
    final msg = await ms.updateMessage(
      dbMsg.id,
      received: dbMsg.received || event.type == 'received' || event.type == 'displayed',
      displayed: dbMsg.displayed || event.type == 'displayed',
    );
    sendEvent(MessageUpdatedEvent(message: msg));

    
    // Update the conversation
    final conv = await cs.getConversationByJid(sender);
    if (conv != null && conv.lastMessage?.id == msg.id) {
      final newConv = conv.copyWith(lastMessage: msg);
      cs.setConversation(newConv);
      _log.finest('Updating conversation');
      sendEvent(ConversationUpdatedEvent(conversation: newConv));
    }
  }

  Future<void> _onChatState(ChatState state, String jid) async {
    final cs = GetIt.I.get<ConversationService>();
    final conversation = await cs.getConversationByJid(jid);
    if (conversation == null) return;

    final newConversation = conversation.copyWith(chatState: state);
    cs.setConversation(newConversation);
    sendEvent(
      ConversationUpdatedEvent(
        conversation: newConversation,
      ),
    );
  }

  /// Return true if [event] describes a message that we want to display.
  bool _isMessageEventMessage(MessageEvent event) {
    return event.body.isNotEmpty || event.sfs != null || event.fun != null;
  }

  /// Extract the thumbnail data from a message, if existent.
  String? _getThumbnailData(MessageEvent event) {
    final thumbnails = firstNotNull([
        event.sfs?.metadata.thumbnails,
        event.fun?.thumbnails,
    ]) ?? [];
    for (final i in thumbnails) {
      if (i is BlurhashThumbnail) {
        return i.hash;
      }
    }

    return null;
  }

  /// Extract the mime guess from a message, if existent.
  String? _getMimeGuess(MessageEvent event) {
    return firstNotNull([
      event.sfs?.metadata.mediaType,
      event.fun?.mediaType,
    ]);
  }

  /// Extract the embedded dimensions, if existent.
  Size? _getDimensions(MessageEvent event) {
    if (event.sfs != null && event.sfs?.metadata.width != null && event.sfs?.metadata.height != null) {
      return Size(
        event.sfs!.metadata.width!.toDouble(),
        event.sfs!.metadata.height!.toDouble(),
      );
    } else if (event.fun != null && event.fun?.width != null && event.fun?.height != null) {
      return Size(
        event.fun!.width!.toDouble(),
        event.fun!.height!.toDouble(),
      );
    }

    return null;
  }
  
  /// Returns true if a file is embedded in [event]. If not, returns false.
  /// [embeddedFile] is the possible source of the file. If no file is present, then
  /// [embeddedFile] is null.
  bool _isFileEmbedded(MessageEvent event, MediaFileLocation? embeddedFile) {
    // True if we determine a file to be embedded. Checks if the Url is using HTTPS and
    // that the message body and the OOB url are the same if the OOB url is not null.
    return embeddedFile != null
      && Uri.parse(embeddedFile.url).scheme == 'https'
      && implies(event.oob != null, event.body == event.oob?.url)
      && event.stickerPackId == null;
  }

  /// Handle a message retraction given the MessageEvent [event].
  Future<void> _handleMessageRetraction(MessageEvent event, String conversationJid) async {
    await GetIt.I.get<MessageService>().retractMessage(
      conversationJid,
      event.messageRetraction!.id,
      event.fromJid.toBare().toString(),
      false,
    );
  }
  
  /// Returns true if a file should be automatically downloaded. If it should not, it
  /// returns false.
  /// [conversationJid] refers to the JID of the conversation the message was received in.
  Future<bool> _shouldDownloadFile(String conversationJid) async {
    return (await Permission.storage.status).isGranted
      && await _automaticFileDownloadAllowed()
      && await GetIt.I.get<RosterService>().isInRoster(conversationJid);
  }

  /// Handles receiving a message stanza of type error.
  Future<void> _handleErrorMessage(MessageEvent event) async {
    if (event.error == null) {
      _log.warning('Received error for message ${event.sid} without an error element');
      return;
    }

    final ms = GetIt.I.get<MessageService>();
    final msg = await ms.getMessageByStanzaId(
      event.fromJid.toBare().toString(),
      event.sid,
    );

    if (msg == null) {
      _log.warning('Received error for message ${event.sid} we cannot find');
      return;
    }

    int error;
    switch (event.error!.error) {
      case 'service-unavailable':
      error = messageServiceUnavailable;
      break;
      case 'remote-server-timeout':
      error = messageRemoteServerTimeout;
      break;
      case 'remote-server-not-found':
      error = messageRemoteServerNotFound;
      break;
      default:
      error = unspecifiedError;
      break;
    }
    
    final newMsg = await ms.updateMessage(
      msg.id,
      errorType: error,
    );

    // TODO(PapaTutuWawa): Show a notification for certain error types, i.e. those
    //                     that mean that the message could not be delivered.
    sendEvent(MessageUpdatedEvent(message: newMsg));
  }

  Future<void> _handleMessageCorrection(MessageEvent event, String conversationJid) async {
    final ms = GetIt.I.get<MessageService>();
    final cs = GetIt.I.get<ConversationService>();
    final msg = await ms.getMessageByStanzaId(conversationJid, event.messageCorrectionId!);
    if (msg == null) {
      _log.warning('Received message correction for message ${event.messageCorrectionId} we cannot find.');
      return;
    }

    // Check if the Jid is allowed to do correct the message
    // TODO(Unknown): Maybe use the JID parser?
    final bareSender = event.fromJid.toBare().toString();
    if (msg.sender.split('/').first != bareSender) {
      _log.warning('Received a message correction from $bareSender for message that is not sent by $bareSender');
      return;
    }
    
    // Check if the message can be corrected
    if (!msg.canEdit(true)) {
      _log.warning('Received a message correction for a message that cannot be edited');
      return;
    }

    final newMsg = await ms.updateMessage(
      msg.id,
      body: event.body,
      isEdited: true,
    );
    sendEvent(MessageUpdatedEvent(message: newMsg));

    final conv = await cs.getConversationByJid(msg.conversationJid);
    if (conv != null && conv.lastMessage?.id == msg.id) {
      final newConv = conv.copyWith(
        lastMessage: newMsg,
      );
      cs.setConversation(newConv);
      sendEvent(ConversationUpdatedEvent(conversation: newConv));
    }
  }

  Future<void> _handleMessageReactions(MessageEvent event, String conversationJid) async {
    final ms = GetIt.I.get<MessageService>();
    // TODO(Unknown): Once we support groupchats, we need to instead query by the stanza-id
    final msg = await ms.getMessageByStanzaOrOriginId(
      conversationJid,
      event.messageReactions!.messageId,
    );
    if (msg == null) {
      _log.warning('Received reactions for ${event.messageReactions!.messageId} from ${event.fromJid} for $conversationJid, but could not find message.');
      return;
    }

    final state = await getXmppState();
    final sender = event.fromJid.toBare().toString();
    final isCarbon = sender == state.jid;
    final reactions = List<Reaction>.from(msg.reactions);
    final emojis = event.messageReactions!.emojis;

    // Find out what emojis the sender has already sent
    final sentEmojis = msg.reactions
      .where((r) {
        return isCarbon ?
          r.reactedBySelf :
          r.senders.contains(sender);
      })
      .map((r) => r.emoji)
      .toList();
    // Find out what reactions were removed
    final removedEmojis = sentEmojis
      .where((e) => !emojis.contains(e));

    for (final emoji in emojis) {
      final i = reactions.indexWhere((r) => r.emoji == emoji);
      if (i == -1) {
        reactions.add(
          Reaction(
            isCarbon ?
              [] :
              [sender],
            emoji,
            isCarbon,
          ),
        );
      } else {
        List<String> senders;
        if (isCarbon) {
          senders = reactions[i].senders;
        } else {
          // Ensure that we don't add a sender multiple times to the same reaction
          if (reactions[i].senders.contains(sender)) {
            senders = reactions[i].senders;
          } else {
            senders = [
              ...reactions[i].senders,
              sender,
            ];
          }
        }
        
        reactions[i] = reactions[i].copyWith(
          senders: senders,
          reactedBySelf: isCarbon ?
            true :
            reactions[i].reactedBySelf,
        );
      }
    }

    for (final emoji in removedEmojis) {
      final i = reactions.indexWhere((r) => r.emoji == emoji);
      assert(i >= -1, 'The reaction must exist');

      if (isCarbon && reactions[i].senders.isEmpty ||
          !isCarbon && reactions[i].senders.length == 1 && !reactions[i].reactedBySelf) {
        reactions.removeAt(i);
      } else {
        reactions[i] = reactions[i].copyWith(
          senders: isCarbon ?
            reactions[i].senders :
            reactions[i].senders
              .where((s) => s != sender)
              .toList(),
          reactedBySelf: isCarbon ?
            false :
            reactions[i].reactedBySelf,
        );
      }
    }

    final newMessage = await ms.updateMessage(
      msg.id,
      reactions: reactions,
    );
    sendEvent(
      MessageUpdatedEvent(message: newMessage),
    );
  }
  
  Future<void> _onMessage(MessageEvent event, { dynamic extra }) async {
    // The jid this message event is meant for
    final conversationJid = event.isCarbon
      ? event.toJid.toBare().toString()
      : event.fromJid.toBare().toString();

    if (event.type == 'error') {
      await _handleErrorMessage(event);
      _log.finest('Processed error message. Ending event processing here.');
      return;
    }
      
    // Process the chat state update. Can also be attached to other messages
    if (event.chatState != null) await _onChatState(event.chatState!, conversationJid);

    // Process message corrections separately
    if (event.messageCorrectionId != null) {
      await _handleMessageCorrection(event, conversationJid);
      return;
    }
    
    // Process File Upload Notifications replacements separately
    if (event.funReplacement != null) {
      await _handleFileUploadNotificationReplacement(event, conversationJid);
      return;
    }

    if (event.messageRetraction != null) {
      await _handleMessageRetraction(event, conversationJid);
      return;
    }

    // Handle message reactions
    if (event.messageReactions != null) {
      await _handleMessageReactions(event, conversationJid);
      return;
    }
    
    // Stop the processing here if the event does not describe a displayable message
    if (!_isMessageEventMessage(event) && event.other['encryption_error'] == null) return;

    final state = await getXmppState();
    final prefs = await GetIt.I.get<PreferencesService>().getPreferences();
    // The (portential) roster item of the chat partner
    final rosterItem = await GetIt.I.get<RosterService>().getRosterItemByJid(conversationJid);
    // Is the conversation partner in our roster
    final isInRoster = rosterItem != null;
    // True if the message was sent by us (via a Carbon)
    final sent = event.isCarbon && event.fromJid.toBare().toString() == state.jid;
    // The timestamp at which we received the message
    final messageTimestamp = DateTime.now().millisecondsSinceEpoch;
    
    // Acknowledge the message if enabled
    if (event.deliveryReceiptRequested && isInRoster && prefs.sendChatMarkers) {
      // NOTE: We do not await it to prevent us being blocked if the IQ response id delayed
      await _acknowledgeMessage(event);
    }

    // Pre-process the message in case it is a reply to another message
    String? replyId;
    var messageBody = event.body;
    // TODO(Unknown): Implement
    if (event.reply != null /* && check if event.reply.to is okay */) {
      replyId = event.reply!.id;

      // Strip the compatibility fallback, if specified
      if (event.reply!.start != null && event.reply!.end != null) {
        messageBody = messageBody.replaceRange(event.reply!.start!, event.reply!.end, '');
        _log.finest('Removed message reply compatibility fallback from message');
      }
    }

    // The Url of the file embedded in the message, if there is one.
    final embeddedFile = _getMessageSrcUrl(event);
    // True if we determine a file to be embedded. Checks if the Url is using HTTPS and
    // that the message body and the OOB url are the same if the OOB url is not null.
    final isFileEmbedded = _isFileEmbedded(event, embeddedFile);
    // Indicates if we should auto-download the file, if a file is specified in the message
    final shouldDownload = await _shouldDownloadFile(conversationJid);
    // The thumbnail for the embedded file.
    final thumbnailData = _getThumbnailData(event);
    // Indicates if a notification should be created for the message.
    // The way this variable works is that if we can download the file, then the
    // notification will be created later by the [DownloadService]. If we don't want the
    // download to happen automatically, then the notification should happen immediately.
    var shouldNotify = !(isFileEmbedded && isInRoster && shouldDownload);
    // A guess for the Mime type of the embedded file.
    var mimeGuess = _getMimeGuess(event);

    // Find a potential sticker
    final stickerId = (await GetIt.I.get<StickersService>().getStickerBySFS(
        event.stickerPackId,
        event.sfs,
      ))?.id;
    
    // Create the message in the database
    final ms = GetIt.I.get<MessageService>();
    final dimensions = _getDimensions(event);
    var message = await ms.addMessageFromData(
      messageBody,
      messageTimestamp,
      event.fromJid.toString(),
      conversationJid,
      isFileEmbedded || event.fun != null || stickerId != null,
      event.sid,
      event.fun != null,
      event.encrypted,
      event.messageProcessingHints?.contains(MessageProcessingHint.noStore) ?? false,
      srcUrl: embeddedFile?.url,
      filename: event.fun?.name ?? embeddedFile?.filename,
      key: embeddedFile?.keyBase64,
      iv: embeddedFile?.ivBase64,
      encryptionScheme: embeddedFile?.encryptionScheme,
      mediaType: mimeGuess,
      thumbnailData: thumbnailData,
      mediaWidth: dimensions?.width.toInt(),
      mediaHeight: dimensions?.height.toInt(),
      quoteId: replyId,
      originId: event.stanzaId.originId,
      errorType: errorTypeFromException(event.other['encryption_error']),
      plaintextHashes: event.sfs?.metadata.hashes,
      stickerPackId: event.stickerPackId,
      stickerId: stickerId,
    );
    
    // Attempt to auto-download the embedded file
    if (isFileEmbedded && shouldDownload) {
      final fts = GetIt.I.get<HttpFileTransferService>();
      final metadata = await peekFile(embeddedFile!.url);

      if (metadata.mime != null) mimeGuess = metadata.mime;

      // Auto-download only if the file is below the set limit, if the limit is not set to
      // "always download".
      if (prefs.maximumAutoDownloadSize == -1
        || (metadata.size != null && metadata.size! < prefs.maximumAutoDownloadSize * 1000000)) {
        message = await ms.updateMessage(
          message.id,
          isDownloading: true,
        );
        await fts.downloadFile(
          FileDownloadJob(
            embeddedFile,
            message.id,
            conversationJid,
            mimeGuess,
          ),
        );
      } else {
        // Make sure we create the notification
        shouldNotify = true;
      }
    }

    final cs = GetIt.I.get<ConversationService>();
    final css = GetIt.I.get<ContactsService>();
    final ns = GetIt.I.get<NotificationsService>();
    // The body to be displayed in the conversations list
    final conversationBody = isFileEmbedded || message.isFileUploadNotification ? mimeTypeToEmoji(mimeGuess) : messageBody;
    // Specifies if we have the conversation this message goes to opened
    final isConversationOpened = _currentlyOpenedChatJid == conversationJid;
    // The conversation we're about to modify, if it exists
    final conversation = await cs.getConversationByJid(conversationJid);
    // If the conversation is muted
    final isMuted = conversation != null ? conversation.muted : prefs.defaultMuteState;
    // Whether to send the notification
    final sendNotification = !sent && shouldNotify && (!isConversationOpened || !_appOpen) && !isMuted;
    if (conversation != null) {
      // The conversation exists, so we can just update it
      final newConversation = await cs.updateConversation(
        conversation.id,
        lastMessage: message,
        lastChangeTimestamp: messageTimestamp,
        // Do not increment the counter for messages we sent ourselves (via Carbons)
        // or if we have the chat currently opened
        unreadCounter: isConversationOpened || sent
          ? conversation.unreadCounter
          : conversation.unreadCounter + 1,
        open: true, 
      );

      // Notify the UI of the update
      sendEvent(ConversationUpdatedEvent(conversation: newConversation));

      // Create the notification if we the user does not already know about the message
      if (sendNotification) {
        await ns.showNotification(
          newConversation,
          message,
          isInRoster ? newConversation.title : conversationJid,
          body: conversationBody,
        );
      }
    } else {
      // The conversation does not exist, so we must create it
      final contactId = await css.getContactIdForJid(conversationJid);
      final newConversation = await cs.addConversationFromData(
        rosterItem?.title ?? conversationJid.split('@')[0],
        message,
        rosterItem?.avatarUrl ?? '',
        conversationJid,
        sent ? 0 : 1,
        messageTimestamp,
        true,
        prefs.defaultMuteState,
        message.encrypted,
        contactId,
        await css.getProfilePicturePathForJid(conversationJid),
        await css.getContactDisplayName(contactId),
      );

      // Notify the UI
      sendEvent(ConversationAddedEvent(conversation: newConversation));

      // Creat the notification
      if (sendNotification) {
        await ns.showNotification(
          newConversation,
          message,
          isInRoster ? newConversation.title : conversationJid,
          body: messageBody,
        );
      }
    }

    // Mark the file as downlading when it includes a File Upload Notification
    if (event.fun != null) {
      message = await ms.updateMessage(
        message.id,
        isDownloading: true,
      );
    }

    // Notify the UI of the message
    sendEvent(MessageAddedEvent(message: message));
  }

  Future<void> _handleFileUploadNotificationReplacement(MessageEvent event, String conversationJid) async {
    final ms = GetIt.I.get<MessageService>();
    var message = await ms.getMessageByStanzaId(conversationJid, event.funReplacement!);
    if (message == null) {
      _log.warning('Received a FileUploadNotification replacement for unknown message');
      return;
    }

    // Check if we can even replace the message
    if (!message.isFileUploadNotification) {
      _log.warning('Received a FileUploadNotification replacement for message that is not marked as a FileUploadNotification');
      return;
    }

    // Check if the Jid is allowed to do so
    // TODO(Unknown): Maybe use the JID parser?
    final bareSender = event.fromJid.toBare().toString();
    if (message.sender.split('/').first != bareSender) {
      _log.warning('Received a FileUploadNotification replacement by $bareSender for message that is not sent by $bareSender');
      return;
    }
    
    // The Url of the file embedded in the message, if there is one.
    final embeddedFile = _getMessageSrcUrl(event);
    // Is there even a file we can download?
    final isFileEmbedded = _isFileEmbedded(event, embeddedFile);

    if (isFileEmbedded) {
      final shouldDownload = await _shouldDownloadFile(conversationJid);
      message = await ms.updateMessage(
        message.id,
        srcUrl: embeddedFile!.url,
        key: embeddedFile.keyBase64,
        iv: embeddedFile.ivBase64,
        isFileUploadNotification: false,
        isDownloading: shouldDownload,
        sid: event.sid,
        originId: event.stanzaId.originId,
      );

      // Tell the UI
      sendEvent(MessageUpdatedEvent(message: message));

      if (shouldDownload) {
        await GetIt.I.get<HttpFileTransferService>().downloadFile(
          FileDownloadJob(
            embeddedFile,
            message.id,
            conversationJid,
            null,
            shouldShowNotification: false,
          ),
        );
      }
    } else {
      _log.warning('Received a File Upload Notification replacement but the replacement contains no file!');
    }
  }
  
  Future<void> _onRosterPush(RosterPushEvent event, { dynamic extra }) async {
    _log.fine("Roster push version: ${event.ver ?? "(null)"}");
    await GetIt.I.get<RosterService>().handleRosterPushEvent(event);
  }

  Future<void> _onAvatarUpdated(AvatarUpdatedEvent event, { dynamic extra }) async {
    await GetIt.I.get<AvatarService>().updateAvatarForJid(
      event.jid,
      event.hash,
      event.base64,
    );
  }
  
  Future<void> _onStanzaAcked(StanzaAckedEvent event, { dynamic extra }) async {
    final jid = JID.fromString(event.stanza.to!).toBare().toString();
    final ms = GetIt.I.get<MessageService>();
    final cs = GetIt.I.get<ConversationService>();
    final msg = await ms.getMessageByStanzaId(jid, event.stanza.id!);
    if (msg != null) {
      // Ack the message
      final newMsg = await ms.updateMessage(msg.id, acked: true);
      sendEvent(MessageUpdatedEvent(message: newMsg));

      // Ack the conversation
      final conv = await cs.getConversationByJid(jid);
      if (conv != null && conv.lastMessage?.id == newMsg.id) {
        final newConv = conv.copyWith(lastMessage: msg);
        cs.setConversation(newConv);
        sendEvent(ConversationUpdatedEvent(conversation: newConv));
      }
    } else {
      _log.finest('Wanted to mark message as acked but did not find the message to ack');
    }
  }

  Future<void> _onBlocklistBlockPush(BlocklistBlockPushEvent event, { dynamic extra }) async {
    await GetIt.I.get<BlocklistService>().onBlocklistPush(BlockPushType.block, event.items);
  }

  Future<void> _onBlocklistUnblockPush(BlocklistUnblockPushEvent event, { dynamic extra }) async {
    await GetIt.I.get<BlocklistService>().onBlocklistPush(BlockPushType.unblock, event.items);
  }

  Future<void> _onBlocklistUnblockAllPush(BlocklistUnblockAllPushEvent event, { dynamic extra }) async {
    GetIt.I.get<BlocklistService>().onUnblockAllPush();
  }

  Future<void> _onStanzaSendingCancelled(StanzaSendingCancelledEvent event, { dynamic extra }) async {
    // We only really care about messages
    if (event.data.stanza.tag != 'message') return;

    final ms = GetIt.I.get<MessageService>();
    final message = await ms.getMessageByStanzaId(
      JID.fromString(event.data.stanza.to!).toBare().toString(),
      event.data.stanza.id!,
    );

    if (message == null) {
      _log.warning('Message could not be sent but we cannot find it in the database');
      return;
    }

    final newMessage = await ms.updateMessage(
      message.id,
      errorType: errorTypeFromException(event.data.cancelReason),
    );


    // Tell the UI
    sendEvent(MessageUpdatedEvent(message: newMessage));
  }

  /// Creates the fallback body for quoted messages.
  /// If the quoted message contains text, it simply quotes the text.
  /// If it contains a media file, the messageEmoji (usually an emoji
  /// representing the mime type) is shown together with the file size
  /// (from experience this information is sufficient, as most clients show
  /// the file size, and including time information might be confusing and a
  /// potential privacy issue).
  /// This information is complemented either the srcUrl or – if unavailable –
  /// by the body of the quoted message. For non-media messages, we always use
  /// the body as fallback.
  String? createFallbackBodyForQuotedMessage(Message? quotedMessage) {
    if (quotedMessage == null) {
      return null;
    }

    if (quotedMessage.isMedia) {
      // Create formatted size string, if size is stored
      String quoteMessageSize;
      if (quotedMessage.mediaSize != null && quotedMessage.mediaSize! > 0) {
        quoteMessageSize = '(${fileSizeToString(quotedMessage.mediaSize!)}) ';
      } else {
        quoteMessageSize = '';
      }

      // Create media url string, or use body if no srcUrl is stored
      String quotedMediaUrl;
      if (quotedMessage.srcUrl != null && quotedMessage.srcUrl!.isNotEmpty) {
        quotedMediaUrl = '• ${quotedMessage.srcUrl!}';
      } else if (quotedMessage.body.isNotEmpty){
        quotedMediaUrl = '• ${quotedMessage.body}';
      } else {
        quotedMediaUrl = '';
      }

      // Concatenate emoji, size string, and media url and return
      return '${quotedMessage.messageEmoji} $quoteMessageSize$quotedMediaUrl';
    } else {
      return quotedMessage.body;
    }
  }
}
