import "dart:async";
import "dart:convert";

import "package:moxxyv2/ui/helpers.dart";
// TODO: Maybe move this file somewhere else
import "package:moxxyv2/ui/redux/account/state.dart";
import "package:moxxyv2/xmpp/settings.dart";
import "package:moxxyv2/xmpp/jid.dart";
import "package:moxxyv2/xmpp/events.dart";
import "package:moxxyv2/xmpp/roster.dart";
import "package:moxxyv2/xmpp/connection.dart";
import "package:moxxyv2/xmpp/managers/namespaces.dart";
import "package:moxxyv2/service/state.dart";
import "package:moxxyv2/service/repositories/roster.dart";
import "package:moxxyv2/service/repositories/database.dart";
import "package:moxxyv2/shared/models/roster.dart";

import "package:get_it/get_it.dart";
import "package:flutter_secure_storage/flutter_secure_storage.dart";
import "package:awesome_notifications/awesome_notifications.dart";
import "package:connectivity_plus/connectivity_plus.dart";
import "package:logging/logging.dart";

const xmppStateKey = "xmppState";
const xmppAccountDataKey = "xmppAccount";

class XmppRepository {
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true)
  );
  final Logger _log;
  final void Function(Map<String, dynamic>) sendData;
  bool loginTriggeredFromUI = false;
  String _currentlyOpenedChatJid;
  StreamSubscription<ConnectivityResult>? _networkStateSubscription;
  XmppState? _state;

  XmppRepository({ required this.sendData }) : _currentlyOpenedChatJid = "", _networkStateSubscription = null, _log = Logger("XmppRepository"), _state = null;

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
      jid: BareJID.fromString(state.jid!),
      password: state.password!,
      useDirectTLS: true,
      allowPlainAuth: false
    );
  }

  /// Marks the conversation with jid [jid] as open and resets its unread counter if it is
  /// greater than 0.
  Future<void> setCurrentlyOpenedChatJid(String jid) async {
    final db = GetIt.I.get<DatabaseRepository>();

    _currentlyOpenedChatJid = jid;
    final conversation = await db.getConversationByJid(jid);

    if (conversation != null && conversation.unreadCounter > 0) {
      final newConversation = await db.updateConversation(id: conversation.id, unreadCounter: 0);
      sendData({
          "type": "ConversationUpdatedEvent",
          "conversation": newConversation.toJson()
      });
    }
  }

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
    final db = GetIt.I.get<DatabaseRepository>();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final message = await db.addMessageFromData(
      body,
      timestamp,
      GetIt.I.get<XmppConnection>().getConnectionSettings().jid.toString(),
      jid,
      true
    );

    sendData({
        "type": "MessageSendResult",
        "message": message.toJson()
    });

    GetIt.I.get<XmppConnection>().getManagerById(messageManager)!.sendMessage(body, jid);

    final conversation = await db.getConversationByJid(jid);
    final newConversation = await db.updateConversation(
      id: conversation!.id,
      lastMessageBody: body,
      lastChangeTimestamp: timestamp
    );
    sendData({
        "type": "ConversationUpdatedEvent",
        "conversation": newConversation.toJson()
    });
  }
  
  Future<void> _handleEvent(XmppEvent event) async {
    if (event is ConnectionStateChangedEvent) {
      sendData({
          "type": "ConnectionStateEvent",
          "state": event.state.toString().split(".")[1]
      });

      // TODO: This will fire as soon as we listen to the stream. So we either have to debounce it here or in [XmppConnection]
      _networkStateSubscription ??= Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
          sendData({ "type": "__LOG__", "log": "Got ConnectivityResult: " + result.toString()});

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

        GetIt.I.get<RosterRepository>().requestRoster();
        
        if (loginTriggeredFromUI) {
          // TODO: Trigger another event so the UI can see this aswell
          await setAccountData(AccountState(
              jid: connection.getConnectionSettings().jid.toString(),
              displayName: connection.getConnectionSettings().jid.local,
              avatarUrl: ""
          ));

          sendData({
              "type": "LoginSuccessfulEvent",
              "jid": connection.getConnectionSettings().jid.toString(),
              "displayName": connection.getConnectionSettings().jid.local
          });
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
    } else if (event is MessageEvent) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final db = GetIt.I.get<DatabaseRepository>();
      final fromBare = event.fromJid.toBare().toString();
      final msg = await db.addMessageFromData(
        event.body,
        timestamp,
        event.fromJid.toString(),
        fromBare,
        false
      );
      final isChatOpen = _currentlyOpenedChatJid == fromBare;
      final isInRoster = await GetIt.I.get<RosterRepository>().isInRoster(fromBare);
      
      final conversation = await db.getConversationByJid(fromBare);
      if (conversation != null) { 
        final newConversation = await db.updateConversation(
          id: conversation.id,
          lastMessageBody: event.body,
          lastChangeTimestamp: timestamp,
          unreadCounter: isChatOpen ? conversation.unreadCounter : conversation.unreadCounter + 1
        );
        sendData({
            "type": "ConversationUpdatedEvent",
            "conversation": newConversation.toJson()
        });

        if (!isChatOpen) {
          AwesomeNotifications().createNotification(
            content: NotificationContent(
              id: msg.id,
              channelKey: "message_channel",
              title: isInRoster ? conversation.title : fromBare,
              body: event.body,
              groupKey: fromBare
            )
          );
        }
      } else {
        final conv = await db.addConversationFromData(
          fromBare.split("@")[0], // TODO: Check with the roster first
          event.body,
          "", // TODO: avatarUrl
          fromBare, // TODO: jid
          1,
          timestamp,
          [],
          true
        );

        sendData({
            "type": "ConversationCreatedEvent",
            "conversation": conv.toJson()
        });

        if (!isChatOpen) {
          AwesomeNotifications().createNotification(
            content: NotificationContent(
              id: msg.id,
              channelKey: "message_channel",
              title: isInRoster ? conv.title : fromBare,
              body: event.body,
              groupKey: fromBare
            )
          );
        }
      }
      
      sendData({
          "type": "MessageReceivedEvent",
          "message": msg.toJson()
      });
    } else if (event is RosterPushEvent) {
      final item = event.item; 

      switch (item.subscription) {
        // TODO: Handle other cases
        case "remove": {
          GetIt.I.get<RosterRepository>().removeFromRoster(item.jid);

          sendData({
              "type": "RosterItemRemovedEvent",
              "jid": item.jid
          });
        }
        break;
        default: {
          (() async {
              final db = GetIt.I.get<DatabaseRepository>();
              final rosterItem = await db.getRosterItemByJid(item.jid);
              final RosterItem modelRosterItem;
              
              if (rosterItem != null) {
                // TODO: Update
                modelRosterItem = await db.updateRosterItem(
                  id: rosterItem.id,
                );
              } else {
                modelRosterItem = await db.addRosterItemFromData(
                  "",
                  item.jid,
                  item.jid.split("@")[0]
                );
              }

              sendData({
                  "type": "RosterItemModifiedEvent",
                  "item": modelRosterItem.toJson()
              });
          })();
        }
        break;
      }

      _log.fine("Roster push version: " + (event.ver ?? "(null)"));
    } else if (event is RosterItemNotFoundEvent) {
      if (event.trigger == RosterItemNotFoundTrigger.remove) {
        sendData({
            "type": "RosterItemRemovedEvent",
            "jid": event.jid
        });
        GetIt.I.get<RosterRepository>().removeFromRoster(event.jid);
      }
    } else if (event is AuthenticationFailedEvent) {
      sendData({
          "type": "LoginFailedEvent",
          "reason": saslErrorToHumanReadable(event.saslError)
      });
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
