import "dart:async";

import "package:moxxyv2/ui/helpers.dart";
import "package:moxxyv2/xmpp/settings.dart";
import "package:moxxyv2/xmpp/jid.dart";
import "package:moxxyv2/xmpp/events.dart";
import "package:moxxyv2/xmpp/roster.dart";
import "package:moxxyv2/xmpp/connection.dart";
import "package:moxxyv2/redux/state.dart";
import "package:moxxyv2/redux/conversation/actions.dart";
import "package:moxxyv2/redux/login/actions.dart";
import "package:moxxyv2/redux/roster/actions.dart";
import "package:moxxyv2/repositories/roster.dart";
import "package:moxxyv2/repositories/database.dart";

import "package:redux/redux.dart";
import "package:get_it/get_it.dart";
import "package:flutter_secure_storage/flutter_secure_storage.dart";

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

  XmppRepository({ required this.sendData });
  
  Future<String?> _readKeyOrNull(String key) async {
    if (await this._storage.containsKey(key: key)) {
      return await this._storage.read(key: key);
    } else {
      return null;
    }
  }

  Future<String?> getLastRosterVersion() async {
    return await this._readKeyOrNull(XMPP_LAST_ROSTER_VERSION_KEY);
  }

  Future<void> saveLastRosterVersion(String ver) async {
    await this._storage.write(key: XMPP_LAST_ROSTER_VERSION_KEY, value: ver);
  }
  
  Future<StreamResumptionSettings> loadStreamResumptionSettings() async {
    final srid = await this._readKeyOrNull(XMPP_ACCOUNT_SRID_KEY);
    final resource = await this._readKeyOrNull(XMPP_ACCOUNT_RESOURCE_KEY);
    final h = await this._readKeyOrNull(XMPP_ACCOUNT_LASTH_KEY);

    return StreamResumptionSettings(
      id: srid,
      lasth: h != null ? int.parse(h) : null,
      resource: resource
    );
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
        allowPlainAuth: false,
        streamResumptionSettings: await this.loadStreamResumptionSettings()
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

  Future<void> _handleEvent(XmppEvent event) async {
    if (event is ConnectionStateChangedEvent) {
      if (event.state == ConnectionState.CONNECTED) {
        final connection = GetIt.I.get<XmppConnection>();
        this.saveConnectionSettings(connection.settings);
        GetIt.I.get<RosterRepository>().requestRoster(await this.getLastRosterVersion());

        if (this.loginTriggeredFromUI) {
          this.sendData({
              "type": "LoginSuccessfulEvent",
              "jid": connection.settings.jid.toString(),
              "displayName": connection.settings.jid.local
          });
        }
      }
    } else if (event is StreamManagementEnabledEvent) {
      this.saveStreamResumptionSettings(event.id, event.resource);
    } else if (event is StreamManagementAckSentEvent) {
      this.saveStreamResumptionLastH(event.h);
    } else if (event is MessageEvent) {
      print("'${event.body}' from ${event.fromJid} (${event.sid})");

      final timestamp = DateTime.now().millisecondsSinceEpoch;

      final db = GetIt.I.get<DatabaseRepository>();
      final fromBare = event.fromJid.toBare().toString();
      await db.addMessageFromData(
        event.body,
        timestamp,
        event.fromJid.toString(),
        fromBare,
        false
      );

      final conversation = await db.getConversationByJid(fromBare);
      if (conversation != null) {
        final newConversation = await db.updateConversation(
          id: conversation.id,
          lastMessageBody: event.body,
          lastChangeTimestamp: timestamp,
          unreadCounter: conversation.unreadCounter + 1 // TODO
        );
        this.sendData({
            "type": "ConversationUpdatedEvent",
            "conversation": newConversation.toJson()
        });
      } else {
        // TODO: Create the conversation
        /*
        this.sendData({
            "type": "ConversationCreatedEvent",
            "conversation": newConversation.toJson()
        });
        */
      }
      
      this.sendData({
          "type": "MessageReceivedEvent",
          "body": event.body,
          "timestamp": timestamp,
          "from": event.fromJid.toString(),
          "conversationJid": fromBare,
          "jid": "" // TODO
      });
    } else if (event is RosterPushEvent) {
      final item = event.item; 

      switch (item.subscription) {
        // TODO: Handle other cases
        case "remove": {
          this.sendData({
              "type": "RosterItemRemovedEvent",
              "jid": item.jid
          });
          GetIt.I.get<RosterRepository>().removeFromRoster(item.jid);
        }
        break;
      }

      print("Roster push version: " + (event.ver ?? "(null)"));
      if (event.ver != null) {
        /* TODO
        this.store.dispatch(SaveCurrentRosterVersionAction(ver: event.ver!));
        */
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

  void connect(ConnectionSettings settings, bool triggeredFromUI) {
    this.loginTriggeredFromUI = triggeredFromUI;
    GetIt.I.get<XmppConnection>().setConnectionSettings(settings);
    GetIt.I.get<XmppConnection>().connect();
    this.installEventHandlers();
  }
}
