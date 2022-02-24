import "package:moxxyv2/xmpp/stanza.dart";
import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/namespaces.dart";

/// Extracts the message stanza from the <forwarded /> node.
Stanza unpackForwarded(XMLNode forwarded) {
  assert(forwarded.attributes["xmlns"] == forwardedXmlns);
  assert(forwarded.tag == "forwarded");

  // NOTE: We only use this XEP (for now) in the context of Message Carbons
  final stanza = forwarded.firstTag("message", xmlns: stanzaXmlns)!;
  return Stanza(
    to: stanza.attributes["to"]!,
    from: stanza.attributes["from"]!,
    type: stanza.attributes["type"]!,
    id: stanza.attributes["id"]!,
    tag: stanza.tag,
    attributes: stanza.attributes as Map<String, String>,
    children: stanza.children
  );
}
