import "package:moxxyv2/xmpp/jid.dart";

class ConnectionSettings {
  final BareJID jid;
  final String password;
  final bool useDirectTLS;

  ConnectionSettings({ required this.jid, required this.password, required this.useDirectTLS});
}
