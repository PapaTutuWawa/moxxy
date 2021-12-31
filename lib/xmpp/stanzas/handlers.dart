import "package:moxxyv2/xmpp/connection.dart";
import "package:moxxyv2/xmpp/stanzas/stanza.dart";

class StanzaHandler {
  final String? xmlns;
  final String? tagName;
  final bool Function(XmppConnection, Stanza) callback;

  StanzaHandler({ this.xmlns, this.tagName, required this.callback });

  bool matches(Stanza stanza) {
    if (this.tagName == null) return true;

    return stanza.firstTag(this.tagName!, xmlns: this.xmlns) != null;
  }
}
