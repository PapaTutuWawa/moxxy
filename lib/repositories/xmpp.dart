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
import "package:moxxyv2/repositories/roster.dart";
import "package:moxxyv2/repositories/database.dart";
import "package:moxxyv2/models/roster.dart";

import "package:get_it/get_it.dart";
import "package:flutter_secure_storage/flutter_secure_storage.dart";
import "package:awesome_notifications/awesome_notifications.dart";
import "package:connectivity_plus/connectivity_plus.dart";

const String xmppAccountSRIDKey = "srid";
const String xmppAccountResourceKey = "resource";
const String xmppAccountC2SKey = "c2sh";
const String xmppAccountS2CKey = "s2ch";
const String xmppAccountJIDKey = "jid";
const String xmppAccountPasswordKey = "password";
const String xmppLastRosterVersionKey = "rosterversion";
const String xmppAccountDataKey = "account";

class XmppRepository {
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true)
  );
  final void Function(Map<String, dynamic>) sendData;
  bool loginTriggeredFromUI = false;
  String _currentlyOpenedChatJid;
  StreamSubscription<ConnectivityResult>? _networkStateSubscription;

  XmppRepository({ required this.sendData }) : _currentlyOpenedChatJid = "", _networkStateSubscription = null;
  
  Future<String?> _readKeyOrNull(String key) async {
    if (await _storage.containsKey(key: key)) {
      return await _storage.read(key: key);
    } else {
      return null;
    }
  }

  Future<String?> getStreamResumptionId() async {
    return await _readKeyOrNull(xmppAccountSRIDKey);
  }
  Future<void> saveStreamResumptionId(String srid) async {
    await _storage.write(key: xmppAccountSRIDKey, value: srid);
  }

  // TODO: Merge those two
  Future<int?> getStreamManagementC2SH() async {
    final value = await _readKeyOrNull(xmppAccountC2SKey);
    return value != null ? int.parse(value) : null;
  }
  Future<void> saveStreamManagementC2SH(int h) async {
    await _storage.write(key: xmppAccountC2SKey, value: h.toString());
  }
  Future<int?> getStreamManagementS2CH() async {
    final value = await _readKeyOrNull(xmppAccountS2CKey);
    return value != null ? int.parse(value) : null;
  }
  Future<void> saveStreamManagementS2CH(int h) async {
    await _storage.write(key: xmppAccountS2CKey, value: h.toString());
  }
  
  Future<String?> getLastRosterVersion() async {
    return await _readKeyOrNull(xmppLastRosterVersionKey);
  }
  Future<void> saveLastRosterVersion(String ver) async {
    await _storage.write(key: xmppLastRosterVersionKey, value: ver);
  }  

  Future<String?> getLastResource() async {
    return await _readKeyOrNull(xmppAccountResourceKey);
  }
  Future<void> saveLastResource(String resource) async {
    await _storage.write(key: xmppAccountResourceKey, value: resource);
  }
  
  Future<ConnectionSettings?> loadConnectionSettings() async {
    final jidString = await _readKeyOrNull(xmppAccountJIDKey);
    final password = await _readKeyOrNull(xmppAccountPasswordKey);

    if (jidString == null || password == null) {
      return null;
    } else {
      return ConnectionSettings(
        jid: BareJID.fromString(jidString),
        password: password,
        useDirectTLS: true,
        allowPlainAuth: false
      );
    }
  }

  // Save the JID and password to secure storage. Note that this does not save stream
  // resumption metadata. For this use saveStreamResumptionSettings
  Future<void> saveConnectionSettings(ConnectionSettings settings) async {
    await _storage.write(key: xmppAccountJIDKey, value: settings.jid.toString());
    await _storage.write(key: xmppAccountPasswordKey, value: settings.password);
  }

  Future<void> saveStreamResumptionSettings(String srid, String resource) async {
    await _storage.write(key: xmppAccountSRIDKey, value: srid);
    await _storage.write(key: xmppAccountResourceKey, value: resource);
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
        saveConnectionSettings(connection.getConnectionSettings());
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
      saveStreamResumptionSettings(event.id, event.resource);
    } else if (event is ResourceBindingSuccessEvent) {
      saveLastResource(event.resource);
    } else if (event is MessageEvent) {
      // TODO: Use logging function
      // ignore: avoid_print
      print("'${event.body}' from ${event.fromJid} (${event.sid})");

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

      // ignore: avoid_print
      print("Roster push version: " + (event.ver ?? "(null)"));
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
    final lastResource = await getLastResource();

    loginTriggeredFromUI = triggeredFromUI;
    GetIt.I.get<XmppConnection>().setConnectionSettings(settings);
    GetIt.I.get<XmppConnection>().connect(lastResource: lastResource);
    installEventHandlers();
  }
}
