import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/namespaces.dart";

/// Represents data provided by XEP-0359.
/// NOTE: [StableStanzaId.stanzaId] must not be confused with the actual id attribute of
///       the message stanza.
class StableStanzaId {
  final String? originId;
  final String? stanzaId;
  final String? stanzaIdBy;

  const StableStanzaId({ this.originId, this.stanzaId, this.stanzaIdBy });
}

XMLNode makeOriginIdElement(String id) {
  return XMLNode.xmlns(
    tag: "origin-id",
    xmlns: stableIdXmlns,
    attributes: { "id": id }
  );
}
