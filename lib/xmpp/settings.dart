import "package:moxxyv2/xmpp/jid.dart";

class StreamResumptionSettings {
  final String? id;
  final int? lasth;
  final String? resource;

  StreamResumptionSettings({ this.id, this.lasth, this.resource });
  StreamResumptionSettings.empty() : id = null, lasth = null, resource = null;
}

class ConnectionSettings {
  final BareJID jid;
  final String password;
  final bool useDirectTLS;
  final bool allowPlainAuth;
  final StreamResumptionSettings streamResumptionSettings;

  ConnectionSettings({ required this.jid, required this.password, required this.useDirectTLS, required this.allowPlainAuth, required this.streamResumptionSettings });
}
