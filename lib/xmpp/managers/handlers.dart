import "package:moxxyv2/shared/helpers.dart";
import "package:moxxyv2/xmpp/namespaces.dart";
import "package:moxxyv2/xmpp/stanza.dart";
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

    if (nonzaTag == null && nonzaXmlns == null) {
      matches = true;
    }

    if (nonzaXmlns != null && nonzaTag != null) {
      matches = (node.attributes["xmlns"] ?? "") == nonzaXmlns! && node.tag == nonzaTag!;
    }
    
    if (matchStanzas && nonzaTag == null) {
      matches = [ "iq", "presence", "message" ].contains(node.tag);
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
      nonzaXmlns: stanzaXmlns,
      callback: (XMLNode node) async => await callback(Stanza.fromXMLNode(node))
    );

  @override
  bool matches(XMLNode node) {
    bool matches = super.matches(node);
    
    if (matches == false) {
      return false;
    }
    
    if (tagName != null) {
      final firstTag = node.firstTag(tagName!, xmlns: tagXmlns);

      matches = firstTag != null;
    } else if (tagXmlns != null) {
      return listContains(
        node.children,
        (XMLNode _node) => _node.attributes.containsKey("xmlns") && _node.attributes["xmlns"] == tagXmlns
      );
    }

    if (tagName == null && tagXmlns == null) {
      matches = true;
    }
    
    return matches;
  }
}
