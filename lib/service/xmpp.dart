import "dart:async";
import "dart:convert";

import "package:moxxyv2/ui/helpers.dart";
import "package:moxxyv2/shared/events.dart";
import "package:moxxyv2/shared/helpers.dart";
import "package:moxxyv2/shared/account.dart";
import "package:moxxyv2/shared/eventhandler.dart";
import "package:moxxyv2/shared/models/message.dart";
import "package:moxxyv2/xmpp/settings.dart";
import "package:moxxyv2/xmpp/jid.dart";
import "package:moxxyv2/xmpp/events.dart";
import "package:moxxyv2/xmpp/roster.dart";
import "package:moxxyv2/xmpp/connection.dart";
import "package:moxxyv2/xmpp/stanza.dart";
import "package:moxxyv2/xmpp/namespaces.dart";
import "package:moxxyv2/xmpp/message.dart";
import "package:moxxyv2/xmpp/managers/namespaces.dart";
import "package:moxxyv2/xmpp/xeps/xep_0184.dart";
import "package:moxxyv2/xmpp/xeps/xep_0333.dart";
import "package:moxxyv2/xmpp/xeps/staging/file_thumbnails.dart";
import "package:moxxyv2/service/service.dart";
import "package:moxxyv2/service/state.dart";
import "package:moxxyv2/service/roster.dart";
import "package:moxxyv2/service/database.dart";
import "package:moxxyv2/service/download.dart";
import "package:moxxyv2/service/notifications.dart";
import "package:moxxyv2/service/avatars.dart";
import "package:moxxyv2/service/preferences.dart";
import "package:moxxyv2/service/blocking.dart";

import "package:get_it/get_it.dart";
import "package:connectivity_plus/connectivity_plus.dart";
import "package:flutter_secure_storage/flutter_secure_storage.dart";
import "package:flutter_background_service/flutter_background_service.dart";

import "package:logging/logging.dart";
import "package:permission_handler/permission_handler.dart";

const xmppStateKey = "xmppState";
const xmppAccountDataKey = "xmppAccount";

class XmppService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true)
  );
  final Logger _log;
  final EventHandler _eventHandler;
  bool loginTriggeredFromUI = false;
  String _currentlyOpenedChatJid;
  StreamSubscription<ConnectivityResult>? _networkStateSubscription;
  XmppState? _state;
  
  ConnectivityResult _currentConnectionType;
  
  XmppService() :
    _currentlyOpenedChatJid = "",
    _networkStateSubscription = null,
    _state = null,
    _currentConnectionType = ConnectivityResult.none,
    _eventHandler = EventHandler(),
    _log = Logger("XmppService") {
      _eventHandler.addMatchers([
          EventTypeMatcher<ConnectionStateChangedEvent>(_onConnectionStateChanged),
          EventTypeMatcher<StreamManagementEnabledEvent>(_onStreamManagementEnabled),
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

  Future<String?> _readKeyOrNull(String key) async {
    if (await _storage.containsKey(key: key)) {
      return await _storage.read(key: key);
    } else {
      return null;
    }
  }
  
  Future<XmppState> getXmppState() async {
    if (_state != null) return _state!;

    final data = await _readKeyOrNull(xmppStateKey);
    // GetIt.I.get<Logger>().finest("data != null: " + (data != null).toString());

    if (data == null) {
      _state = XmppState();
      await _commitXmppState();
      return _state!;
    }

    _state = XmppState.fromJson(json.decode(data));
    return _state!;
  }
  
  Future<void> _commitXmppState() async {
    // final logger = GetIt.I.get<Logger>();
    // logger.finest("Commiting _xmppState to EncryptedSharedPrefs");
    // logger.finest("=> ${json.encode(_state!.toJson())}");
    await _storage.write(key: xmppStateKey, value: json.encode(_state!.toJson()));
  }

  /// A wrapper to modify the [XmppState] and commit it.
  Future<void> modifyXmppState(XmppState Function(XmppState) func) async {
    _state = func(_state!);
    await _commitXmppState();
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
      allowPlainAuth: false
    );
  }

  /// Marks the conversation with jid [jid] as open and resets its unread counter if it is
  /// greater than 0.
  Future<void> setCurrentlyOpenedChatJid(String jid) async {
    final db = GetIt.I.get<DatabaseService>();

    _currentlyOpenedChatJid = jid;
    final conversation = await db.getConversationByJid(jid);

    if (conversation != null && conversation.unreadCounter > 0) {
      final newConversation = await db.updateConversation(
        id: conversation.id,
        unreadCounter: 0
      );

      sendEvent(
        ConversationUpdatedEvent(conversation: newConversation)
      );
    }
  }

  /// Returns the JID of the chat that is currently opened. Null, if none is open.
  String? getCurrentlyOpenedChatJid() => _currentlyOpenedChatJid;
  
  /// Load the [AccountState] from storage. Returns null if not found.
  Future<AccountState?> getAccountData() async {
    final data = await _readKeyOrNull(xmppAccountDataKey);
    if (data == null) {
      return null;
    }

    return AccountState.fromJson(jsonDecode(data));
  }
  /// Save [state] to storage such that it can be loaded again by [getAccountData].
  Future<void> setAccountData(AccountState state) async {
    return await _storage.write(key: xmppAccountDataKey, value: jsonEncode(state.toJson()));
  }
  /// Removes the account data from storage.
  Future<void> removeAccountData() async {
    // TODO: This sometimes fails
    await _storage.delete(key: xmppAccountDataKey);
  }

  /// Sends a message to [jid] with the body of [body].
  Future<void> sendMessage({
      required String body,
      required String jid,
      Message? quotedMessage,
      String? commandId
  }) async {
    final db = GetIt.I.get<DatabaseService>();
    final conn = GetIt.I.get<XmppConnection>();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final sid = conn.generateId();
    final originId = conn.generateId();
    final message = await db.addMessageFromData(
      body,
      timestamp,
      conn.getConnectionSettings().jid.toString(),
      jid,
      true,
      false,
      sid,
      originId: originId,
      quoteId: quotedMessage?.originId ?? quotedMessage?.sid
    );

    if (commandId != null) {
      sendEvent(
        MessageAddedEvent(message: message),
        id: commandId
      );
    }
    
    conn.getManagerById(messageManager)!.sendMessage(
      MessageDetails(
        to: jid,
        body: body,
        requestDeliveryReceipt: true,
        id: sid,
        originId: originId,
        quoteBody: quotedMessage?.body,
        quoteFrom: quotedMessage?.from,
        quoteId: quotedMessage?.originId ?? quotedMessage?.sid
      )
    );

    final conversation = await db.getConversationByJid(jid);
    final newConversation = await db.updateConversation(
      id: conversation!.id,
      lastMessageBody: body,
      lastChangeTimestamp: timestamp
    );

    sendEvent(
      ConversationUpdatedEvent(conversation: newConversation)
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
    final info = await GetIt.I.get<XmppConnection>().getDiscoCacheManager().getInfoByJid(event.fromJid.toString());
    if (info == null) return;

    if (event.isMarkable && info.features.contains(chatMarkersXmlns)) {
      GetIt.I.get<XmppConnection>().sendStanza(
        Stanza.message(
          to: event.fromJid.toBare().toString(),
          type: event.type,
          children: [
            makeChatMarker("received", event.stanzaId.originId ?? event.sid)
          ]
        )
      );
    } else if (event.deliveryReceiptRequested && info.features.contains(deliveryXmlns)) {
      GetIt.I.get<XmppConnection>().sendStanza(
        Stanza.message(
          to: event.fromJid.toBare().toString(),
          type: event.type,
          children: [
            makeMessageDeliveryResponse(event.stanzaId.originId ?? event.sid)
          ]
        )
      );
    }
  }

  /// Returns true if we are allowed to automatically download a file
  Future<bool> _canDownloadFile() async {
    final prefs = await GetIt.I.get<PreferencesService>().getPreferences();

    return prefs.autoDownloadWifi && _currentConnectionType == ConnectivityResult.wifi || prefs.autoDownloadMobile && _currentConnectionType == ConnectivityResult.mobile;
  }
 
  void installEventHandlers() {
    GetIt.I.get<XmppConnection>().asBroadcastStream().listen(_eventHandler.run);
  }

  Future<void> connect(ConnectionSettings settings, bool triggeredFromUI) async {
    final lastResource = (await getXmppState()).resource;

    loginTriggeredFromUI = triggeredFromUI;
    GetIt.I.get<XmppConnection>().setConnectionSettings(settings);
    GetIt.I.get<XmppConnection>().connect(lastResource: lastResource);
    installEventHandlers();
  }

  Future<XmppConnectionResult> connectAwaitable(ConnectionSettings settings, bool triggeredFromUI) async {
    final lastResource = (await getXmppState()).resource;

    loginTriggeredFromUI = triggeredFromUI;
    GetIt.I.get<XmppConnection>().setConnectionSettings(settings);
    installEventHandlers();
    return GetIt.I.get<XmppConnection>().connectAwaitable(lastResource: lastResource);
  }

  Future<void> _onConnectionStateChanged(ConnectionStateChangedEvent event, { dynamic extra }) async {
    switch (event.state) {
      case XmppConnectionState.connected: {
        FlutterBackgroundService().setNotificationInfo(title: "Moxxy", content: "Ready to receive messages");
      }
      break;
      case XmppConnectionState.connecting: {
        FlutterBackgroundService().setNotificationInfo(title: "Moxxy", content: "Connecting...");
      }
      break;
      default: {
        FlutterBackgroundService().setNotificationInfo(title: "Moxxy", content: "Disconnected");
      }
      break;
    }
    
    // TODO: This will fire as soon as we listen to the stream. So we either have to debounce it here or in [XmppConnection]
    _networkStateSubscription ??= Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
        _log.fine("Got ConnectivityResult: " + result.toString());

        switch (result) { 
          case ConnectivityResult.none: {
            GetIt.I.get<XmppConnection>().onNetworkConnectionLost();
          }
          break;
          case ConnectivityResult.wifi: {
            _currentConnectionType = ConnectivityResult.wifi;
            // TODO: This will crash inside [XmppConnection] as soon as this happens
            GetIt.I.get<XmppConnection>().onNetworkConnectionRegained();
          }
          break;
          case ConnectivityResult.mobile: {
            _currentConnectionType = ConnectivityResult.mobile;
            // TODO: This will crash inside [XmppConnection] as soon as this happens
            GetIt.I.get<XmppConnection>().onNetworkConnectionRegained();
          }
          break;
          case ConnectivityResult.ethernet: {
            // NOTE: A hack, but should be fine
            _currentConnectionType = ConnectivityResult.wifi;
            // TODO: This will crash inside [XmppConnection] as soon as this happens
            GetIt.I.get<XmppConnection>().onNetworkConnectionRegained();
          }
          break;
          default: break;
        }
    });
    
    if (event.state == XmppConnectionState.connected) {
      final connection = GetIt.I.get<XmppConnection>();

      // TODO: Maybe have something better
      final settings = connection.getConnectionSettings();
      modifyXmppState((state) => state.copyWith(
          jid: settings.jid.toString(),
          password: settings.password.toString()
      ));

      // In section 5 of XEP-0198 it says that a client should not request the roster
      // in case of a stream resumption.
      if (!event.resumed) {
        GetIt.I.get<RosterService>().requestRoster();
        // Request our own avatar and maybe those of our contacts
      }

      // Either we get the cached version or we retrieve it for the first time
      GetIt.I.get<BlocklistService>().getBlocklist();
      
      if (loginTriggeredFromUI) {
        // TODO: Trigger another event so the UI can see this aswell
        await setAccountData(AccountState(
            jid: connection.getConnectionSettings().jid.toString(),
            displayName: connection.getConnectionSettings().jid.local,
            avatarUrl: ""
        ));
      }
    }
  }

  Future<void> _onStreamManagementEnabled(StreamManagementEnabledEvent event, { dynamic extra }) async {
    // TODO: Remove
    modifyXmppState((state) => state.copyWith(
        srid: event.id,
        resource: event.resource
    ));
  }

  Future<void> _onResourceBindingSuccess(ResourceBindingSuccessEvent event, { dynamic extra }) async {
    modifyXmppState((state) => state.copyWith(
        resource: event.resource
    ));
  }

  Future<void> _onSubscriptionRequestReceived(SubscriptionRequestReceivedEvent event, { dynamic extra }) async {
    final prefs = await GetIt.I.get<PreferencesService>().getPreferences();

    if (prefs.autoAcceptSubscriptionRequests) {
      GetIt.I.get<XmppConnection>().getPresenceManager().sendSubscriptionRequestApproval(
        event.from.toBare().toString()
      );
    }

    if (!prefs.showSubscriptionRequests) return;
    
    final db = GetIt.I.get<DatabaseService>();
    final conversation = await db.getConversationByJid(event.from.toBare().toString());
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    if (conversation != null) { 
      final newConversation = await db.updateConversation(
        id: conversation.id,
        open: true,
        lastChangeTimestamp: timestamp
      );

      sendEvent(ConversationUpdatedEvent(conversation: newConversation));
    } else {
      // TODO: Make it configurable if this should happen
      final bare = event.from.toBare();
      final conv = await db.addConversationFromData(
        bare.toString().split("@")[0],
        "",
        "", // TODO: avatarUrl
        bare.toString(),
        0,
        timestamp,
        [],
        true
      );

      sendEvent(ConversationAddedEvent(conversation: conv));
    }
  }

  Future<void> _onDeliveryReceiptReceived(DeliveryReceiptReceivedEvent event, { dynamic extra }) async {
    _log.finest("Received delivery receipt from ${event.from.toString()}");
    final db = GetIt.I.get<DatabaseService>();
    final dbMsg = await db.getMessageByXmppId(event.id, event.from.toBare().toString());
    if (dbMsg == null) {
      _log.warning("Did not find the message with id ${event.id} in the database!");
      return;
    }
    
    final msg = await db.updateMessage(
      id: dbMsg.id!,
      received: true
    );

    sendEvent(MessageUpdatedEvent(message: msg));
  }

  Future<void> _onChatMarker(ChatMarkerEvent event, { dynamic extra }) async {
    _log.finest("Chat marker from ${event.from.toString()}");
    if (event.type == "acknowledged") return;

    final db = GetIt.I.get<DatabaseService>();
    final dbMsg = await db.getMessageByXmppId(event.id, event.from.toBare().toString());
    if (dbMsg == null) {
      _log.warning("Did not find the message in the database!");
      return;
    }
    
    final msg = await db.updateMessage(
      id: dbMsg.id!,
      received: dbMsg.received || event.type == "received" || event.type == "displayed",
      displayed: dbMsg.displayed || event.type == "displayed"
    );

    sendEvent(MessageUpdatedEvent(message: msg));
  }

  Future<void> _onMessage(MessageEvent event, { dynamic extra }) async {
    // TODO: Clean this huge mess up
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final db = GetIt.I.get<DatabaseService>();
    final fromBare = event.fromJid.toBare().toString();
    final isChatOpen = _currentlyOpenedChatJid == fromBare;
    final isInRoster = await GetIt.I.get<RosterService>().isInRoster(fromBare);
    final srcUrl = _getMessageSrcUrl(event);
    final isMedia = srcUrl != null && Uri.parse(srcUrl).scheme == "https" && implies(event.oob != null, event.body == event.oob?.url);
    final prefs = await GetIt.I.get<PreferencesService>().getPreferences();
    String dbBody = event.body;
    String? replyId;
    
    // Respond to the message delivery request
    if (event.deliveryReceiptRequested && isInRoster && prefs.sendChatMarkers) {
      // NOTE: We do not await it to prevent us being blocked if the IQ response id delayed
      _acknowledgeMessage(event);
    }
    
    String? thumbnailData;
    final thumbnails = firstNotNull([ event.sfs?.metadata.thumbnails, event.sims?.thumbnails ]) ?? [];
    for (final i in thumbnails) {
      if (i is BlurhashThumbnail) {
        thumbnailData = i.hash;
        break;
      }
    }

    // TODO
    if (event.reply != null /* && check if event.reply.to is okay */) {
      replyId = event.reply!.id;
      if (event.reply!.start != null && event.reply!.end != null) {
        dbBody = dbBody.replaceRange(event.reply!.start!, event.reply!.end!, "");
        _log.finest("Removed message reply compatibility fallback from message");
      }
    }


    final ext = srcUrl != null ? filenameFromUrl(srcUrl) : null;
    String? mimeGuess = guessMimeTypeFromExtension(ext ?? "");
    Message msg = await db.addMessageFromData(
      dbBody,
      timestamp,
      event.fromJid.toString(),
      fromBare,
      false,
      isMedia,
      event.sid,
      srcUrl: srcUrl,
      mediaType: mimeGuess,
      thumbnailData: thumbnailData,
      thumbnailDimensions: event.sfs?.metadata.dimensions,
      quoteId: replyId
    );

    final canDownload = (await Permission.storage.status).isGranted && await _canDownloadFile();

    bool shouldNotify = !(isMedia && isInRoster && canDownload);
    if (isMedia && isInRoster && canDownload) {
      final download = GetIt.I.get<DownloadService>();
      final metadata = await download.peekFile(srcUrl);

      if (metadata.mime != null) {
        mimeGuess = metadata.mime!;
      }

      if (prefs.maximumAutoDownloadSize == -1 || (metadata.size != null && metadata.size! <= prefs.maximumAutoDownloadSize * 1000000)) {
        msg = msg.copyWith(isDownloading: true);
        // NOTE: If we are here, then srcUrl must be non-null
        download.downloadFile(srcUrl, msg.id, fromBare, mimeGuess);
      } else {
        shouldNotify = true;
      }
    }

    final body = isMedia ? mimeTypeToConversationBody(mimeGuess) : event.body;
    final conversation = await db.getConversationByJid(fromBare);
    if (conversation != null) { 
      final newConversation = await db.updateConversation(
        id: conversation.id,
        lastMessageBody: body,
        lastChangeTimestamp: timestamp,
        unreadCounter: isChatOpen ? conversation.unreadCounter : conversation.unreadCounter + 1
      );

      sendEvent(ConversationUpdatedEvent(conversation: newConversation));

      if (!isChatOpen && shouldNotify) {
        await GetIt.I.get<NotificationsService>().showNotification(msg, isInRoster ? conversation.title : fromBare, body: body);
      }
    } else {
      final conv = await db.addConversationFromData(
        fromBare.split("@")[0], // TODO: Check with the roster first
        body,
        "", // TODO: avatarUrl
        fromBare, // TODO: jid
        1,
        timestamp,
        [],
        true
      );

      sendEvent(
        ConversationAddedEvent(
          conversation: conv
        )
      );

      if (!isChatOpen && shouldNotify) {
        await GetIt.I.get<NotificationsService>().showNotification(msg, isInRoster ? conv.title : fromBare, body: body);
      }
    }

    sendEvent(MessageAddedEvent(message: msg));
  }

  Future<void> _onRosterPush(RosterPushEvent event, { dynamic extra }) async {
    GetIt.I.get<RosterService>().handleRosterPushEvent(event);
    _log.fine("Roster push version: " + (event.ver ?? "(null)"));
  }

  Future<void> _onAvatarUpdated(AvatarUpdatedEvent event, { dynamic extra }) async {
    await GetIt.I.get<AvatarService>().updateAvatarForJid(
      event.jid,
      event.hash,
      event.base64
    );
  }
  
  Future<void> _onMessageAcked(MessageAckedEvent event, { dynamic extra }) async {
    final jid = JID.fromString(event.to).toBare().toString();
    final db = GetIt.I.get<DatabaseService>();
    final msg = await db.getMessageByXmppId(event.id, jid);
    if (msg != null) {
      await db.updateMessage(id: msg.id!, acked: true);
    } else {
      _log.finest("Wanted to mark message as acked but did not find the message to ack");
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
