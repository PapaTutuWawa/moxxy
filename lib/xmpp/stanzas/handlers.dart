import "package:moxxyv2/helpers.dart";
import "package:moxxyv2/xmpp/connection.dart";
import "package:moxxyv2/xmpp/stanzas/stanza.dart";
import "package:moxxyv2/xmpp/stringxml.dart";

class StanzaHandler {
  final String? xmlns;
  final String? tagName;
  final String? stanzaTag;
  final bool Function(XmppConnection, Stanza) callback;

  StanzaHandler({ this.xmlns, this.tagName, this.stanzaTag, required this.callback });

  bool matches(Stanza stanza) {
    bool matches = false;

    if (stanzaTag != null && stanza.tag == stanzaTag) {
      matches = true;
    }
    
    if (this.tagName != null) {
      final node = stanza.firstTag(this.tagName!, xmlns: this.xmlns);

      matches = node != null;
    } else if (this.xmlns != null) {
      return listContains(stanza.children, (XMLNode node) => node.attributes.containsKey("xmlns") && node.attributes["xmlns"] == this.xmlns);
    }

    if (this.tagName == null && this.stanzaTag == null && this.xmlns == null) {
      return true;
    }
    
    return matches;
  }
}
