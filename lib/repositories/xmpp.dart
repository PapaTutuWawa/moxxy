import "dart:async";

import "package:moxxyv2/xmpp/settings.dart";
import "package:moxxyv2/xmpp/jid.dart";
import "package:moxxyv2/xmpp/events.dart";
import "package:moxxyv2/xmpp/connection.dart";
import "package:moxxyv2/redux/state.dart";
import "package:moxxyv2/redux/conversation/actions.dart";
import "package:moxxyv2/redux/login/actions.dart";

import "package:redux/redux.dart";
import "package:get_it/get_it.dart";
import "package:flutter_secure_storage/flutter_secure_storage.dart";

const String XMPP_ACCOUNT_SRID_KEY = "srid";
const String XMPP_ACCOUNT_RESOURCE_KEY = "resource";
const String XMPP_ACCOUNT_LASTH_KEY = "lasth";
const String XMPP_ACCOUNT_JID_KEY = "jid";
const String XMPP_ACCOUNT_PASSWORD_KEY = "password";

class XmppRepository {
  final FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true)
  );
  final Store<MoxxyState> store;
  bool loginTriggeredFromUI = false;

  XmppRepository({ required this.store });
  
  Future<String?> _readKeyOrNull(String key) async {
    if (await this._storage.containsKey(key: key)) {
      return await this._storage.read(key: key);
    } else {
      return null;
    }
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

        if (this.loginTriggeredFromUI) {
          this.store.dispatch(LoginSuccessfulAction(
              jid: connection.settings.jid.toString(),
              displayName: connection.settings.jid.local
          ));
        }
      }
    } else if (event is StreamManagementEnabledEvent) {
      this.saveStreamResumptionSettings(event.id, event.resource);
    } else if (event is StreamManagementAckSentEvent) {
      this.saveStreamResumptionLastH(event.h);
    } else if (event is MessageEvent) {
      print("'${event.body}' from ${event.fromJid} (${event.sid})");
      this.store.dispatch(ReceiveMessageAction(
          body: event.body,
          timestamp: DateTime.now().millisecondsSinceEpoch,
          from: event.fromJid,
          jid: "" // TODO
      ));
    }
  }
  
  void installEventHandlers() {
    GetIt.I.get<XmppConnection>().asBroadcastStream().listen(this._handleEvent);
  }

  void connect(ConnectionSettings settings, bool triggeredFromUI) {
    this.loginTriggeredFromUI = triggeredFromUI;
    GetIt.I.registerSingleton<XmppConnection>(XmppConnection(
        settings: settings
    ));
    GetIt.I.get<XmppConnection>().connect();
    this.installEventHandlers();
  }
}
