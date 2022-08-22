import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:mime/mime.dart';
import 'package:moxlib/moxlib.dart';
import 'package:moxplatform/moxplatform.dart';
import 'package:moxxyv2/service/avatars.dart';
import 'package:moxxyv2/service/blocking.dart';
import 'package:moxxyv2/service/connectivity.dart';
import 'package:moxxyv2/service/connectivity_watcher.dart';
import 'package:moxxyv2/service/conversation.dart';
import 'package:moxxyv2/service/database.dart';
import 'package:moxxyv2/service/db/media.dart';
import 'package:moxxyv2/service/httpfiletransfer/helpers.dart';
import 'package:moxxyv2/service/httpfiletransfer/httpfiletransfer.dart';
import 'package:moxxyv2/service/httpfiletransfer/jobs.dart';
import 'package:moxxyv2/service/message.dart';
import 'package:moxxyv2/service/notifications.dart';
import 'package:moxxyv2/service/preferences.dart';
import 'package:moxxyv2/service/roster.dart';
import 'package:moxxyv2/service/service.dart';
import 'package:moxxyv2/service/state.dart';
import 'package:moxxyv2/shared/eventhandler.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/shared/migrator.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/xmpp/connection.dart';
import 'package:moxxyv2/xmpp/events.dart';
import 'package:moxxyv2/xmpp/jid.dart';
import 'package:moxxyv2/xmpp/managers/namespaces.dart';
import 'package:moxxyv2/xmpp/message.dart';
import 'package:moxxyv2/xmpp/namespaces.dart';
import 'package:moxxyv2/xmpp/roster.dart';
import 'package:moxxyv2/xmpp/settings.dart';
import 'package:moxxyv2/xmpp/stanza.dart';
import 'package:moxxyv2/xmpp/xeps/staging/file_thumbnails.dart';
import 'package:moxxyv2/xmpp/xeps/staging/file_upload_notification.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0085.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0184.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0333.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0446.dart';
import 'package:path/path.dart' as pathlib;
import 'package:permission_handler/permission_handler.dart';

const currentXmppStateVersion = 1;
const xmppStateKey = 'xmppState';
const xmppStateVersionKey = 'xmppState_version';

class _XmppStateMigrator extends Migrator<XmppState> {

  _XmppStateMigrator() : super(currentXmppStateVersion, []);
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    // TODO(Unknown): Set other options
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  // TODO(Unknown): Deduplicate
  Future<String?> _readKeyOrNull(String key) async {
    if (await _storage.containsKey(key: key)) {
      return _storage.read(key: key);
    } else {
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>?> loadRawData() async {
    final raw = await _readKeyOrNull(xmppStateKey);
    if (raw != null) return json.decode(raw) as Map<String, dynamic>;

    return null;
  }

  @override
  Future<int?> loadVersion() async {
    final raw = await _readKeyOrNull(xmppStateVersionKey);
    if (raw != null) return int.parse(raw);

    return null;
  }

  @override
  XmppState fromData(Map<String, dynamic> data) => XmppState.fromJson(data);

  @override
  XmppState fromDefault() => XmppState();
  
  @override
  Future<void> commit(int version, XmppState data) async {
    await _storage.write(key: xmppStateVersionKey, value: currentXmppStateVersion.toString());
    await _storage.write(key: xmppStateKey, value: json.encode(data.toJson()));
  }
}

class XmppService {
  
  XmppService() :
    _currentlyOpenedChatJid = '',
    _xmppConnectionSubscription = null,
    _state = null,
    _eventHandler = EventHandler(),
    _appOpen = true,
    _loginTriggeredFromUI = false,
    _migrator = _XmppStateMigrator(),
    _log = Logger('XmppService') {
      _eventHandler.addMatchers([
        EventTypeMatcher<ConnectionStateChangedEvent>(_onConnectionStateChanged),
        EventTypeMatcher<ResourceBindingSuccessEvent>(_onResourceBindingSuccess),
        EventTypeMatcher<SubscriptionRequestReceivedEvent>(_onSubscriptionRequestReceived),
        EventTypeMatcher<DeliveryReceiptReceivedEvent>(_onDeliveryReceiptReceived),
        EventTypeMatcher<ChatMarkerEvent>(_onChatMarker),
        EventTypeMatcher<RosterPushEvent>(_onRosterPush),
        EventTypeMatcher<AvatarUpdatedEvent>(_onAvatarUpdated),
        EventTypeMatcher<MessageAckedEvent>(_onMessageAcked),
        EventTypeMatcher<MessageEvent>(_onMessage),
        EventTypeMatcher<BlocklistBlockPushEvent>(_onBlocklistBlockPush),
        EventTypeMatcher<BlocklistUnblockPushEvent>(_onBlocklistUnblockPush),
        EventTypeMatcher<BlocklistUnblockAllPushEvent>(_onBlocklistUnblockAllPush),
      ]);
    }
  final Logger _log;
  final EventHandler _eventHandler;
  final _XmppStateMigrator _migrator;
  bool _loginTriggeredFromUI;
  bool _appOpen;
  String _currentlyOpenedChatJid;
  StreamSubscription<dynamic>? _xmppConnectionSubscription;
  XmppState? _state;

  Future<XmppState> getXmppState() async {
    if (_state != null) return _state!;

    _state = await _migrator.load();
    return _state!;
  }

  /// A wrapper to modify the [XmppState] and commit it.
  Future<void> modifyXmppState(XmppState Function(XmppState) func) async {
    _state = func(_state!);
    await _migrator.commit(currentXmppStateVersion, _state!);
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
  
  /// Sends a message to [jid] with the body of [body].
  Future<void> sendMessage({
      required String body,
      required String jid,
      Message? quotedMessage,
      String? commandId,
      ChatState? chatState,
  }) async {
    final ms = GetIt.I.get<MessageService>();
    final cs = GetIt.I.get<ConversationService>();
    final conn = GetIt.I.get<XmppConnection>();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final sid = conn.generateId();
    final originId = conn.generateId();
    final message = await ms.addMessageFromData(
      body,
      timestamp,
      conn.getConnectionSettings().jid.toString(),
      jid,
      true,
      false,
      sid,
      originId: originId,
      quoteId: quotedMessage?.originId ?? quotedMessage?.sid,
    );

    if (commandId != null) {
      sendEvent(
        MessageAddedEvent(message: message),
        id: commandId,
      );
    }
    
    conn.getManagerById<MessageManager>(messageManager)!.sendMessage(
      MessageDetails(
        to: jid,
        body: body,
        requestDeliveryReceipt: true,
        id: sid,
        originId: originId,
        quoteBody: quotedMessage?.body,
        quoteFrom: quotedMessage?.from,
        quoteId: quotedMessage?.originId ?? quotedMessage?.sid,
        chatState: chatState,
      ),
    );

    final conversation = await cs.getConversationByJid(jid);
    final newConversation = await cs.updateConversation(
      conversation!.id,
      lastMessageBody: body,
      lastChangeTimestamp: timestamp,
    );

    sendEvent(
      ConversationUpdatedEvent(conversation: newConversation),
    );
  }

  String? _getMessageSrcUrl(MessageEvent event) {
    if (event.sfs != null) {
      return event.sfs!.url;
    } else if (event.sims != null) {
      return event.sims!.url;
    } else if (event.oob != null) {
      return event.oob!.url;
    }

    return null;
  }

  Future<void> _acknowledgeMessage(MessageEvent event) async {
    final info = await GetIt.I.get<XmppConnection>().getDiscoManager().discoInfoQuery(event.fromJid.toString());
    if (info == null) return;

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

  Future<void> sendFiles(List<String> paths, String recipient) async {
    // Create a new message
    final ms = GetIt.I.get<MessageService>();
    final cs = GetIt.I.get<ConversationService>();

    // TODO(Unknown): This has a huge issue. The messages should get sent to the UI
    //                as soon as possible to indicate to the user that we are working on
    //                them. But if the files are big, then copying them might take a little
    //                while. The solution might be to use the real path before copying as
    //                the messages initial mediaUrl attribute and once the file has been
    //                copied replace it with the new path. Meanwhile, the file can also be
    //                uploaded from its original location.
    
    // Path -> Message
    final messages = <String, Message>{};

    // Create the messages and shared media entries
    final conn = GetIt.I.get<XmppConnection>();
    for (final path in paths) {
      final msg = await ms.addMessageFromData(
        '',
        DateTime.now().millisecondsSinceEpoch, 
        conn.getConnectionSettings().jid.toString(),
        recipient,
        true,
        true,
        conn.generateId(),
        mediaUrl: path,
        mediaType: lookupMimeType(path),
        originId: conn.generateId(),
      );
      messages[path] = msg;
      sendEvent(MessageAddedEvent(message: msg.copyWith(isUploading: true)));

      // Send an upload notification
      conn.getManagerById<MessageManager>(messageManager)!.sendMessage(
        MessageDetails(
          to: recipient,
          fun: FileUploadNotificationData(
            FileMetadataData(
              // TODO(Unknown): Maybe add media type specific metadata
              mediaType: lookupMimeType(path),
              name: pathlib.basename(path),
              size: File(path).statSync().size,
              // TODO(Unknown): Implement thumbnails
              thumbnails: [],
            ),
          ),
        ),
      );
    }

    // Create the shared media entries
    final sharedMedia = List<DBSharedMedium>.empty(growable: true);
    for (final path in paths) {
      sharedMedia.add(
        await GetIt.I.get<DatabaseService>().addSharedMediumFromData(
          path,
          DateTime.now().millisecondsSinceEpoch,
          mime: lookupMimeType(path),
        ),
      );
    }

    // Update conversation
    final lastFileMime = lookupMimeType(paths.last);
    final conversationId = (await cs.getConversationByJid(recipient))!.id;
    final updatedConversation = await cs.updateConversation(
      conversationId,
      lastMessageBody: mimeTypeToConversationBody(lastFileMime),
      lastChangeTimestamp: DateTime.now().millisecondsSinceEpoch,
      sharedMedia: sharedMedia,
    );
    sendEvent(ConversationUpdatedEvent(conversation: updatedConversation));

    // Requesting Upload slots and uploading
    final hfts = GetIt.I.get<HttpFileTransferService>();
    for (final path in paths) {
      final pathMime = lookupMimeType(path);
      await hfts.uploadFile(
        FileUploadJob(
          recipient,
          path,
          await getDownloadPath(pathlib.basename(path), recipient, pathMime),
          messages[path]!,
        ),
      );
    }

    _log.finest('File upload done');
  }
  
  Future<void> _onConnectionStateChanged(ConnectionStateChangedEvent event, { dynamic extra }) async {
    switch (event.state) {
      case XmppConnectionState.connected:
        GetIt.I.get<BackgroundService>().setNotification(
          'Moxxy',
          'Ready to receive messages',
        );
      break;
      case XmppConnectionState.connecting:
        GetIt.I.get<BackgroundService>().setNotification(
          'Moxxy',
          'Connecting...',
        );
      break;
      case XmppConnectionState.notConnected:
        GetIt.I.get<BackgroundService>().setNotification(
          'Moxxy',
          'Disconnected',
        );
      break;
      case XmppConnectionState.error:
        GetIt.I.get<BackgroundService>().setNotification(
          'Moxxy',
          'Error',
        );
      break;
    }

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
      if (!event.resumed) {
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
    
    final cs = GetIt.I.get<ConversationService>();
    final conversation = await cs.getConversationByJid(event.from.toBare().toString());
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    if (conversation != null) { 
      final newConversation = await cs.updateConversation(
        conversation.id,
        open: true,
        lastChangeTimestamp: timestamp,
      );
      sendEvent(ConversationUpdatedEvent(conversation: newConversation));
    } else {
      // TODO(Unknown): Make it configurable if this should happen
      final bare = event.from.toBare();
      final conv = await cs.addConversationFromData(
        bare.toString().split('@')[0],
        '',
        '', // TODO(Unknown): avatarUrl
        bare.toString(),
        0,
        timestamp,
        [],
        true,
      );

      sendEvent(ConversationAddedEvent(conversation: conv));
    }
  }

  Future<void> _onDeliveryReceiptReceived(DeliveryReceiptReceivedEvent event, { dynamic extra }) async {
    _log.finest('Received delivery receipt from ${event.from.toString()}');
    final db = GetIt.I.get<DatabaseService>();
    final ms = GetIt.I.get<MessageService>();
    final dbMsg = await db.getMessageByXmppId(event.id, event.from.toBare().toString());
    if (dbMsg == null) {
      _log.warning('Did not find the message with id ${event.id} in the database!');
      return;
    }
    
    final msg = await ms.updateMessage(
      dbMsg.id!,
      received: true,
    );

    sendEvent(MessageUpdatedEvent(message: msg));
  }

  Future<void> _onChatMarker(ChatMarkerEvent event, { dynamic extra }) async {
    _log.finest('Chat marker from ${event.from.toString()}');
    if (event.type == 'acknowledged') return;

    final db = GetIt.I.get<DatabaseService>();
    final ms = GetIt.I.get<MessageService>();
    final dbMsg = await db.getMessageByXmppId(event.id, event.from.toBare().toString());
    if (dbMsg == null) {
      _log.warning('Did not find the message in the database!');
      return;
    }
    
    final msg = await ms.updateMessage(
      dbMsg.id!,
      received: dbMsg.received || event.type == 'received' || event.type == 'displayed',
      displayed: dbMsg.displayed || event.type == 'displayed',
    );

    sendEvent(MessageUpdatedEvent(message: msg));
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
    return event.body.isNotEmpty || event.sfs != null || event.sims != null;
  }

  /// Extract the thumbnail data from a message, if existent.
  String? _getThumbnailData(MessageEvent event) {
    final thumbnails = firstNotNull([
        event.sfs?.metadata.thumbnails,
        event.sims?.thumbnails
    ]) ?? [];
    for (final i in thumbnails) {
      if (i is BlurhashThumbnail) {
        return i.hash;
      }
    }

    return null;
  }
  
  Future<void> _onMessage(MessageEvent event, { dynamic extra }) async {
    // The jid this message event is meant for
    final conversationJid = event.isCarbon
      ? event.toJid.toBare().toString()
      : event.fromJid.toBare().toString();

    // Process the chat state update. Can also be attached to other messages
    if (event.chatState != null) await _onChatState(event.chatState!, conversationJid);

    // Stop the processing here if the event does not describe a displayable message
    if (!_isMessageEventMessage(event)) return;

    final state = await getXmppState();
    final prefs = await GetIt.I.get<PreferencesService>().getPreferences();
    // Is the conversation partner in our roster
    final isInRoster = await GetIt.I.get<RosterService>().isInRoster(conversationJid);
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
    final embeddedFileUrl = _getMessageSrcUrl(event);
    // True if we determine a file to be embedded. Checks if the Url is using HTTPS and
    // that the message body and the OOB url are the same if the OOB url is not null.
    final isFileEmbedded = embeddedFileUrl != null
      && Uri.parse(embeddedFileUrl).scheme == 'https'
      && implies(event.oob != null, event.body == event.oob?.url);
    // Indicates if we should auto-download the file, if a file is specified in the message
    final shouldDownload = (await Permission.storage.status).isGranted
      && await _automaticFileDownloadAllowed()
      && isInRoster;
    // The thumbnail for the embedded file.
    final thumbnailData = _getThumbnailData(event);
    // Indicates if a notification should be created for the message.
    // The way this variable works is that if we can download the file, then the
    // notification will be created later by the [DownloadService]. If we don't want the
    // download to happen automatically, then the notification should happen immediately.
    var shouldNotify = !(isFileEmbedded && isInRoster && shouldDownload);
    // A guess for the Mime type of the embedded file.
    String? mimeGuess;

    // Create the message in the database
    final ms = GetIt.I.get<MessageService>();
    var message = await ms.addMessageFromData(
      messageBody,
      messageTimestamp,
      event.fromJid.toString(),
      conversationJid,
      sent,
      isFileEmbedded,
      event.sid,
      srcUrl: embeddedFileUrl,
      mediaType: mimeGuess,
      thumbnailData: thumbnailData,
      // TODO(Unknown): What about SIMS?
      thumbnailDimensions: event.sfs?.metadata.dimensions,
      quoteId: replyId,
    );
    
    // Attempt to auto-download the embedded file
    if (isFileEmbedded && shouldDownload) {
      final fts = GetIt.I.get<HttpFileTransferService>();
      final metadata = await peekFile(embeddedFileUrl);

      if (metadata.mime != null) mimeGuess = metadata.mime;

      // Auto-download only if the file is below the set limit, if the limit is not set to
      // "always download".
      if (prefs.maximumAutoDownloadSize == -1
        || (metadata.size != null && metadata.size! < prefs.maximumAutoDownloadSize * 1000000)) {
        message = message.copyWith(isDownloading: true);
        await fts.downloadFile(
          FileDownloadJob(
            embeddedFileUrl,
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
    final ns = GetIt.I.get<NotificationsService>();
    // The body to be displayed in the conversations list
    final conversationBody = isFileEmbedded ? mimeTypeToConversationBody(mimeGuess) : messageBody;
    // Specifies if we have the conversation this message goes to opened
    final isConversationOpened = _currentlyOpenedChatJid == conversationJid;
    // The conversation we're about to modify, if it exists
    final conversation = await cs.getConversationByJid(conversationJid);
    // Whether to send the notification
    final sendNotification = !sent && shouldNotify && (!isConversationOpened || !_appOpen);
    if (conversation != null) {
      // The conversation exists, so we can just update it
      final newConversation = await cs.updateConversation(
        conversation.id,
        lastMessageBody: conversationBody,
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
          message,
          isInRoster ? newConversation.title : conversationJid,
          body: conversationBody,
        );
      }
    } else {
      // The conversation does not exist, so we must create it
      final newConversation = await cs.addConversationFromData(
        conversationJid.split('@')[0], // TODO(Unknown): Check with the roster and User Nickname
        conversationBody,
        '', // TODO(Unknown): Check if we know the avatar url already, e.g. from the roster
        conversationJid,
        sent ? 0 : 1,
        messageTimestamp,
        [],
        true,
      );

      // Notify the UI
      sendEvent(ConversationAddedEvent(conversation: newConversation));

      // Creat the notification
      if (sendNotification) {
        await ns.showNotification(
          message,
          isInRoster ? newConversation.title : conversationJid,
          body: messageBody,
        );
      }
    }

    // Notify the UI of the message
    sendEvent(MessageAddedEvent(message: message));
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
  
  Future<void> _onMessageAcked(MessageAckedEvent event, { dynamic extra }) async {
    final jid = JID.fromString(event.to).toBare().toString();
    final db = GetIt.I.get<DatabaseService>();
    final ms = GetIt.I.get<MessageService>();
    final msg = await db.getMessageByXmppId(event.id, jid);
    if (msg != null) {
      await ms.updateMessage(msg.id!, acked: true);
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
}
