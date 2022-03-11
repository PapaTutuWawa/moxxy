import "package:moxxyv2/shared/helpers.dart";
import "package:moxxyv2/xmpp/namespaces.dart";
import "package:moxxyv2/xmpp/stanza.dart";
import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/managers/data.dart";

abstract class Handler {
  final String? nonzaTag;
  final String? nonzaXmlns;
  final bool matchStanzas;

  const Handler(this.matchStanzas, { this.nonzaTag, this.nonzaXmlns });

  /// Returns true if the node matches the description provided by this [Handler].
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

class NonzaHandler extends Handler {
  final Future<bool> Function(XMLNode) callback;

  NonzaHandler({
      required this.callback,
      String? nonzaTag,
      String? nonzaXmlns
  }) : super(
    false,
    nonzaTag: nonzaTag,
    nonzaXmlns: nonzaXmlns
  );
}

class StanzaHandler extends Handler {
  final String? tagName;
  final String? tagXmlns;
  final int priority;
  final Future<StanzaHandlerData> Function(Stanza, StanzaHandlerData) callback;

  StanzaHandler({
      required this.callback,
      this.tagXmlns,
      this.tagName,     
      this.priority = 0,
      String? stanzaTag,
  }) : super(
      true,
      nonzaTag: stanzaTag,
      nonzaXmlns: stanzaXmlns
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

int stanzaHandlerSortComparator(StanzaHandler a, StanzaHandler b) => b.priority.compareTo(a.priority);
