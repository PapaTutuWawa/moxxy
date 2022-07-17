import 'package:moxxyv2/xmpp/jid.dart';

class ConnectionSettings {

  ConnectionSettings({ required this.jid, required this.password, required this.useDirectTLS, required this.allowPlainAuth });
  final JID jid;
  final String password;
  final bool useDirectTLS;
  final bool allowPlainAuth;
}
