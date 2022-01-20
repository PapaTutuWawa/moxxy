import "dart:async";

import "package:moxxyv2/ui/helpers.dart";
import "package:moxxyv2/xmpp/settings.dart";
import "package:moxxyv2/xmpp/jid.dart";
import "package:moxxyv2/xmpp/events.dart";
import "package:moxxyv2/xmpp/roster.dart";
import "package:moxxyv2/xmpp/connection.dart";
import "package:moxxyv2/repositories/roster.dart";
import "package:moxxyv2/repositories/database.dart";
import "package:moxxyv2/models/roster.dart";

import "package:redux/redux.dart";
import "package:get_it/get_it.dart";
import "package:flutter_secure_storage/flutter_secure_storage.dart";
import "package:awesome_notifications/awesome_notifications.dart";
import "package:connectivity_plus/connectivity_plus.dart";

const String XMPP_ACCOUNT_SRID_KEY = "srid";
const String XMPP_ACCOUNT_RESOURCE_KEY = "resource";
const String XMPP_ACCOUNT_LASTH_KEY = "lasth";
const String XMPP_ACCOUNT_JID_KEY = "jid";
const String XMPP_ACCOUNT_PASSWORD_KEY = "password";
const String XMPP_LAST_ROSTER_VERSION_KEY = "rosterversion";

class XmppRepository {
  final FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true)
  );
  final void Function(Map<String, dynamic>) sendData;
  bool loginTriggeredFromUI = false;
  String _currentlyOpenedChatJid;
  StreamSubscription<ConnectivityResult>? _networkStateSubscription;

  XmppRepository({ required this.sendData }) : _currentlyOpenedChatJid = "", _networkStateSubscription = null;
  
  Future<String?> _readKeyOrNull(String key) async {
    if (await this._storage.containsKey(key: key)) {
      return await this._storage.read(key: key);
    } else {
      return null;
    }
  }

  Future<String?> getStreamResumptionId() async {
    return await _readKeyOrNull(XMPP_ACCOUNT_SRID_KEY);
  }
  Future<void> saveStreamResumptionId(String srid) async {
    await _storage.write(key: XMPP_ACCOUNT_SRID_KEY, value: srid);
  }

  Future<int?> getStreamManagementLastH() async {
    final value = await _readKeyOrNull(XMPP_ACCOUNT_LASTH_KEY);
    return value != null ? int.parse(value) : null;
  }
  Future<void> saveStreamManagementLastH(int h) async {
    await this._storage.write(key: XMPP_ACCOUNT_LASTH_KEY, value: h.toString());
  }
  
  Future<String?> getLastRosterVersion() async {
    return await this._readKeyOrNull(XMPP_LAST_ROSTER_VERSION_KEY);
  }
  Future<void> saveLastRosterVersion(String ver) async {
    await this._storage.write(key: XMPP_LAST_ROSTER_VERSION_KEY, value: ver);
  }  

  Future<String?> getLastResource() async {
    return await _readKeyOrNull(XMPP_ACCOUNT_RESOURCE_KEY);
  }
  Future<void> saveLastResource(String resource) async {
    await _storage.write(key: XMPP_ACCOUNT_RESOURCE_KEY, value: resource);
  }
  
  Future<ConnectionSettings?> loadConnectionSettings() async {
    final jidString = await this._readKeyOrNull(XMPP_ACCOUNT_JID_KEY);
    final password = await this._readKeyOrNull(XMPP_ACCOUNT_PASSWORD_KEY);

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
    await this._storage.write(key: XMPP_ACCOUNT_JID_KEY, value: settings.jid.toString());
    await this._storage.write(key: XMPP_ACCOUNT_PASSWORD_KEY, value: settings.password);
  }

  Future<void> saveStreamResumptionSettings(String srid, String resource) async {
    await this._storage.write(key: XMPP_ACCOUNT_SRID_KEY, value: srid);
    await this._storage.write(key: XMPP_ACCOUNT_LASTH_KEY, value: "0");
    await this._storage.write(key: XMPP_ACCOUNT_RESOURCE_KEY, value: resource);
  }

  Future<void> saveStreamResumptionLastH(int h) async {
    await this._storage.write(key: XMPP_ACCOUNT_LASTH_KEY, value: h.toString());
  }

  /// Marks the conversation with jid [jid] as open and resets its unread counter if it is
  /// greater than 0.
  Future<void> setCurrentlyOpenedChatJid(String jid) async {
    final db = GetIt.I.get<DatabaseRepository>();

    this._currentlyOpenedChatJid = jid;
    final conversation = await db.getConversationByJid(jid);

    if (conversation != null && conversation.unreadCounter > 0) {
      final newConversation = await db.updateConversation(id: conversation.id, unreadCounter: 0);
      this.sendData({
          "type": "ConversationUpdatedEvent",
          "conversation": newConversation.toJson()
      });
    }
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

    this.sendData({
        "type": "MessageSendResult",
        "message": message.toJson()
    });

    GetIt.I.get<XmppConnection>().sendMessage(body, jid);

    final conversation = await db.getConversationByJid(jid);
    final newConversation = await db.updateConversation(
      id: conversation!.id,
      lastMessageBody: body,
      lastChangeTimestamp: timestamp
    );
    this.sendData({
        "type": "ConversationUpdatedEvent",
        "conversation": newConversation.toJson()
    });
  }
  
  Future<void> _handleEvent(XmppEvent event) async {
    if (event is ConnectionStateChangedEvent) {
      this.sendData({
          "type": "ConnectionStateEvent",
          "state": event.state.toString().split(".")[1]
      });

      if (this._networkStateSubscription == null) {
        // TODO: This will fire as soon as we listen to the stream. So we either have to debounce it here or in [XmppConnection]
        this._networkStateSubscription = Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
            this.sendData({ "type": "__LOG__", "log": "Got ConnectivityResult: " + result.toString()});

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
            }
        });
      }
      
      if (event.state == ConnectionState.CONNECTED) {
        final connection = GetIt.I.get<XmppConnection>();
        this.saveConnectionSettings(connection.getConnectionSettings());
        GetIt.I.get<RosterRepository>().requestRoster();
        
        if (this.loginTriggeredFromUI) {
          this.sendData({
              "type": "LoginSuccessfulEvent",
              "jid": connection.getConnectionSettings().jid.toString(),
              "displayName": connection.getConnectionSettings().jid.local
          });
        }
      }
    } else if (event is StreamManagementEnabledEvent) {
      this.saveStreamResumptionSettings(event.id, event.resource);
    } else if (event is StreamManagementAckSentEvent) {
      this.saveStreamResumptionLastH(event.h);
    } else if (event is ResourceBindingSuccessEvent) {
      saveLastResource(event.resource);
    } else if (event is MessageEvent) {
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
      final isChatOpen = this._currentlyOpenedChatJid == fromBare;
      final isInRoster = await GetIt.I.get<RosterRepository>().isInRoster(fromBare);
      
      final conversation = await db.getConversationByJid(fromBare);
      if (conversation != null) { 
        final newConversation = await db.updateConversation(
          id: conversation.id,
          lastMessageBody: event.body,
          lastChangeTimestamp: timestamp,
          unreadCounter: isChatOpen ? conversation.unreadCounter : conversation.unreadCounter + 1
        );
        this.sendData({
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

        this.sendData({
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
      
      this.sendData({
          "type": "MessageReceivedEvent",
          "message": msg.toJson()
      });
    } else if (event is RosterPushEvent) {
      final item = event.item; 

      switch (item.subscription) {
        // TODO: Handle other cases
        case "remove": {
          GetIt.I.get<RosterRepository>().removeFromRoster(item.jid);

          this.sendData({
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
                  "", // TODO
                  item.jid,
                  item.jid.split("@")[0]
                );
              }

              this.sendData({
                  "type": "RosterItemModifiedEvent",
                  "item": modelRosterItem.toJson()
              });
          })();
        }
        break;
      }

      print("Roster push version: " + (event.ver ?? "(null)"));
      if (event.ver != null) {
        this.saveLastRosterVersion(event.ver!);
      }
    } else if (event is RosterItemNotFoundEvent) {
      if (event.trigger == RosterItemNotFoundTrigger.REMOVE) {
        this.sendData({
            "type": "RosterItemRemovedEvent",
            "jid": event.jid
        });
        GetIt.I.get<RosterRepository>().removeFromRoster(event.jid);
      }
    } else if (event is AuthenticationFailedEvent) {
      this.sendData({
          "type": "LoginFailedEvent",
          "reason": saslErrorToHumanReadable(event.saslError)
      });
    }
  }
  
  void installEventHandlers() {
    GetIt.I.get<XmppConnection>().asBroadcastStream().listen(this._handleEvent);
  }

  Future<void> connect(ConnectionSettings settings, bool triggeredFromUI) async {
    final lastResource = await this.getLastResource();

    this.loginTriggeredFromUI = triggeredFromUI;
    GetIt.I.get<XmppConnection>().setConnectionSettings(settings);
    GetIt.I.get<XmppConnection>().connect(lastResource: lastResource);
    this.installEventHandlers();
  }
}
