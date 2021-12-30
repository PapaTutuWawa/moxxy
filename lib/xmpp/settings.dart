import "package:moxxyv2/xmpp/jid.dart";

class ConnectionSettings {
  final BareJID jid;
  final String password;

  ConnectionSettings({ required this.jid, required this.password });
}
