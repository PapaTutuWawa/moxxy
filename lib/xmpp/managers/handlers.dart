import "package:moxxyv2/helpers.dart";
import "package:moxxyv2/xmpp/namespaces.dart";
import "package:moxxyv2/xmpp/stanzas/stanza.dart";
import "package:moxxyv2/xmpp/stringxml.dart";

class NonzaHandler {
  final String? nonzaTag;
  final String? nonzaXmlns;
  final bool matchStanzas;
  final Future<bool> Function(XMLNode) callback;

  NonzaHandler({ this.nonzaTag, this.nonzaXmlns, required this.callback, this.matchStanzas = false });

  /// Returns true if the node matches the description provided by this NonzaHandler
  bool matches(XMLNode node) {
    bool matches = false;

    if (this.nonzaTag == null && this.nonzaXmlns == null) {
      matches = true;
    }

    if (this.nonzaXmlns != null && this.nonzaTag != null) {
      matches = (node.attributes["xmlns"] ?? "") == this.nonzaXmlns! && node.tag == this.nonzaTag!;
    }
    
    if (this.matchStanzas && this.nonzaTag == null) {
      matches = [ "iq", "presence", "message" ].indexOf(node.tag) != -1;
    }

    return matches;
  }
}

class StanzaHandler extends NonzaHandler {
  final String? tagXmlns;
  final String? tagName;

  StanzaHandler({ this.tagXmlns, this.tagName, String? stanzaTag, required Future<bool> Function(Stanza) callback }) : super(
      matchStanzas: true,
      nonzaTag: stanzaTag,
      nonzaXmlns: STANZA_XMLNS,
      callback: (XMLNode node) async => await callback(Stanza.fromXMLNode(node))
    );

  @override
  bool matches(XMLNode node) {
    bool matches = super.matches(node);
    
    if (matches == false) {
      return false;
    }
    
    if (this.tagName != null) {
      final firstTag = node.firstTag(this.tagName!, xmlns: this.tagXmlns);

      matches = firstTag != null;
    } else if (this.tagXmlns != null) {
      return listContains(
        node.children,
        (XMLNode _node) => _node.attributes.containsKey("xmlns") && _node.attributes["xmlns"] == this.tagXmlns
      );
    }

    if (this.tagName == null && this.tagXmlns == null) {
      matches = true;
    }
    
    return matches;
  }
}
