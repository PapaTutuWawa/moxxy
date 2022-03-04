import "dart:async";
import "dart:convert";

import "package:moxxyv2/ui/helpers.dart";

// TODO: Maybe move this file somewhere else
import "package:moxxyv2/ui/redux/account/state.dart";

import "package:moxxyv2/shared/events.dart";
import "package:moxxyv2/shared/helpers.dart";
import "package:moxxyv2/shared/models/message.dart";
import "package:moxxyv2/xmpp/settings.dart";
import "package:moxxyv2/xmpp/jid.dart";
import "package:moxxyv2/xmpp/events.dart";
import "package:moxxyv2/xmpp/roster.dart";
import "package:moxxyv2/xmpp/connection.dart";
import "package:moxxyv2/xmpp/stanza.dart";
import "package:moxxyv2/xmpp/managers/namespaces.dart";
import "package:moxxyv2/xmpp/xeps/xep_0184.dart";
import "package:moxxyv2/xmpp/xeps/staging/file_thumbnails.dart";
import "package:moxxyv2/service/state.dart";
import "package:moxxyv2/service/roster.dart";
import "package:moxxyv2/service/database.dart";
import "package:moxxyv2/service/download.dart";
import "package:moxxyv2/service/notifications.dart";
import "package:moxxyv2/service/avatars.dart";
import "package:moxxyv2/service/preferences.dart";

import "package:get_it/get_it.dart";
import "package:flutter_secure_storage/flutter_secure_storage.dart";
import "package:connectivity_plus/connectivity_plus.dart";
import "package:logging/logging.dart";
import "package:permission_handler/permission_handler.dart";

const xmppStateKey = "xmppState";
const xmppAccountDataKey = "xmppAccount";

class XmppService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true)
  );
  final Logger _log;
  final void Function(BaseIsolateEvent) sendData;
  bool loginTriggeredFromUI = false;
  String _currentlyOpenedChatJid;
  StreamSubscription<ConnectivityResult>? _networkStateSubscription;
  XmppState? _state;

  XmppService({ required this.sendData }) : _currentlyOpenedChatJid = "", _networkStateSubscription = null, _log = Logger("XmppService"), _state = null;

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
      _state = XmppState(
        0,
        0,
        "",
        "",
        0,
        false
      );

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
      sendData(ConversationUpdatedEvent(conversation: newConversation));
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
  Future<void> sendMessage({ required String body, required String jid }) async {
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
      originId: originId
    );

    sendData(MessageSendResultEvent(message: message));

    conn.getManagerById(messageManager)!.sendMessage(
      body,
      jid,
      deliveryRequest: true,
      id: sid,
      originId: originId
    );

    final conversation = await db.getConversationByJid(jid);
    final newConversation = await db.updateConversation(
      id: conversation!.id,
      lastMessageBody: body,
      lastChangeTimestamp: timestamp
    );
    sendData(ConversationUpdatedEvent(conversation: newConversation));
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
  
  Future<void> _handleEvent(XmppEvent event) async {
    if (event is ConnectionStateChangedEvent) {
      sendData(ConnectionStateEvent(state: event.state.toString().split(".")[1]));

      // TODO: This will fire as soon as we listen to the stream. So we either have to debounce it here or in [XmppConnection]
      _networkStateSubscription ??= Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
          _log.fine("Got ConnectivityResult: " + result.toString());

          switch (result) { 
            case ConnectivityResult.none: {
              GetIt.I.get<XmppConnection>().onNetworkConnectionLost();
            }
            break;
            case ConnectivityResult.wifi:
            case ConnectivityResult.mobile:
            case ConnectivityResult.ethernet: {
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
        
        if (loginTriggeredFromUI) {
          // TODO: Trigger another event so the UI can see this aswell
          await setAccountData(AccountState(
              jid: connection.getConnectionSettings().jid.toString(),
              displayName: connection.getConnectionSettings().jid.local,
              avatarUrl: ""
          ));

          sendData(LoginSuccessfulEvent(
              jid: connection.getConnectionSettings().jid.toString(),
              displayName: connection.getConnectionSettings().jid.local
          ));
        }
      }
    } else if (event is StreamManagementEnabledEvent) {
      // TODO: Remove
      modifyXmppState((state) => state.copyWith(
          srid: event.id,
          resource: event.resource
      ));
    } else if (event is ResourceBindingSuccessEvent) {
      modifyXmppState((state) => state.copyWith(
          resource: event.resource
      ));
    } else if (event is SubscriptionRequestReceivedEvent) {
      final prefs = await GetIt.I.get<PreferencesService>().getPreferences();
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
        sendData(ConversationUpdatedEvent(conversation: newConversation));
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

        sendData(ConversationCreatedEvent(conversation: conv));
      }
    } else if (event is DeliveryReceiptReceivedEvent) {
      _log.finest("Received delivery receipt from ${event.from.toString()}");
      final db = GetIt.I.get<DatabaseService>();
      final dbMsg = await db.getMessageByXmppId(event.id);
      if (dbMsg == null) {
        _log.warning("Did not find the message in the database!");
        return;
      }
      
      final msg = await db.updateMessage(
        id: dbMsg.id!,
        received: true
      );

      sendData(MessageUpdatedEvent(message: msg));
    } else if (event is ChatMarkerEvent) {
      _log.finest("Chat marker from ${event.from.toString()}");
      if (event.type == "acknowledged") return;

      final db = GetIt.I.get<DatabaseService>();
      final dbMsg = await db.getMessageByXmppId(event.id);
      if (dbMsg == null) {
        _log.warning("Did not find the message in the database!");
        return;
      }
      
      final msg = await db.updateMessage(
        id: dbMsg.id!,
        received: dbMsg.received || event.type == "received" || event.type == "displayed",
        displayed: dbMsg.displayed || event.type == "displayed"
      );

      sendData(MessageUpdatedEvent(message: msg));
    } else if (event is MessageEvent) {
      _log.finest("Received message with origin-id: " + (event.stanzaId.originId ?? "null"));
      _log.finest("Delivery receipt requested? " + event.deliveryReceiptRequested.toString());

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final db = GetIt.I.get<DatabaseService>();
      final fromBare = event.fromJid.toBare().toString();
      final isChatOpen = _currentlyOpenedChatJid == fromBare;
      final isInRoster = await GetIt.I.get<RosterService>().isInRoster(fromBare);
      final srcUrl = _getMessageSrcUrl(event);
      final isMedia = srcUrl != null && Uri.parse(srcUrl).scheme == "https" && implies(event.oob != null, event.body == event.oob?.url);
      final prefs = await GetIt.I.get<PreferencesService>().getPreferences();
      
      // Respond to the message delivery request
      if (event.deliveryReceiptRequested && isInRoster && prefs.sendChatMarkers) {
        GetIt.I.get<XmppConnection>().sendStanza(
          Stanza.message(
            to: event.fromJid.toBare().toString(),
            type: "normal",
            children: [
              makeMessageDeliveryResponse(event.stanzaId.originId ?? event.sid)
            ]
          )
        );
      }
      
      String? thumbnailData;
      final thumbnails = firstNotNull([ event.sfs?.metadata.thumbnails, event.sims?.thumbnails ]) ?? [];
      for (final i in thumbnails) {
        if (i is BlurhashThumbnail) {
          thumbnailData = i.hash;
          break;
        }
      }

      Message msg = await db.addMessageFromData(
        event.body,
        timestamp,
        event.fromJid.toString(),
        fromBare,
        false,
        isMedia,
        event.sid,
        srcUrl: srcUrl,
        thumbnailData: thumbnailData,
        thumbnailDimensions: event.sfs?.metadata.dimensions
      );

      final canDownload = (await Permission.storage.status).isGranted;
      final shouldNotify = !(isMedia && isInRoster && canDownload);
      String? mimeGuess;
      if (isMedia && isInRoster && canDownload) {
        final download = GetIt.I.get<DownloadService>();
        final metadata = await download.peekFile(srcUrl);

        // NOTE: This either works by returing "jpg" for ".../hallo.jpg" or fails
        //       for ".../aaaaaaaaa", in which case we would've failed anyways.
        final ext = srcUrl.split(".").last;
        mimeGuess = metadata.mime ?? guessMimeTypeFromExtension(ext);

        msg = msg.copyWith(isDownloading: true);
        // TODO: Check the file size first
        // NOTE: If we are here, then srcUrl must be non-null
        download.downloadFile(srcUrl, msg.id, fromBare, mimeGuess);
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
        sendData(ConversationUpdatedEvent(conversation: newConversation));

        if (!isChatOpen && shouldNotify) {
          await GetIt.I.get<NotificationsService>().showNotification(msg, isInRoster ? conversation.title : fromBare);
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

        sendData(ConversationCreatedEvent(conversation: conv));

        if (!isChatOpen && shouldNotify) {
          await GetIt.I.get<NotificationsService>().showNotification(msg, isInRoster ? conv.title : fromBare);
        }
      }
      
      sendData(MessageReceivedEvent(message: msg));
    } else if (event is RosterPushEvent) {
      GetIt.I.get<RosterService>().handleRosterPushEvent(event);
      _log.fine("Roster push version: " + (event.ver ?? "(null)"));
    } else if (event is AuthenticationFailedEvent) {
      sendData(LoginFailedEvent(reason: saslErrorToHumanReadable(event.saslError)));
    } else if (event is AvatarUpdatedEvent) {
      await GetIt.I.get<AvatarService>().updateAvatarForJid(
        event.jid,
        event.hash,
        event.base64
      );
    }
  }
  
  void installEventHandlers() {
    GetIt.I.get<XmppConnection>().asBroadcastStream().listen(_handleEvent);
  }

  Future<void> connect(ConnectionSettings settings, bool triggeredFromUI) async {
    final lastResource = (await getXmppState()).resource;

    loginTriggeredFromUI = triggeredFromUI;
    GetIt.I.get<XmppConnection>().setConnectionSettings(settings);
    GetIt.I.get<XmppConnection>().connect(lastResource: lastResource);
    installEventHandlers();
  }
}
