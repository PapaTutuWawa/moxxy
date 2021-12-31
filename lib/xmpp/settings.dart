import "package:moxxyv2/xmpp/jid.dart";

class ConnectionSettings {
  final BareJID jid;
  final String password;
  final bool useDirectTLS;
  final bool allowPlainAuth;
  final String? streamResumptionId;
  final String? resource;

  ConnectionSettings({ required this.jid, required this.password, required this.useDirectTLS, required this.allowPlainAuth, this.streamResumptionId, this.resource });
}
