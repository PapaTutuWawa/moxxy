import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/xmpp/managers/data.dart';
import 'package:moxxyv2/xmpp/namespaces.dart';
import 'package:moxxyv2/xmpp/stanza.dart';
import 'package:moxxyv2/xmpp/stringxml.dart';

abstract class Handler {

  const Handler(this.matchStanzas, { this.nonzaTag, this.nonzaXmlns });
  final String? nonzaTag;
  final String? nonzaXmlns;
  final bool matchStanzas;

  /// Returns true if the node matches the description provided by this [Handler].
  bool matches(XMLNode node) {
    var matches = false;

    if (nonzaTag == null && nonzaXmlns == null) {
      matches = true;
    }

    if (nonzaXmlns != null && nonzaTag != null) {
      matches = (node.attributes['xmlns'] ?? '') == nonzaXmlns! && node.tag == nonzaTag!;
    }
    
    if (matchStanzas && nonzaTag == null) {
      matches = [ 'iq', 'presence', 'message' ].contains(node.tag);
    }

    return matches;
  }
}

class NonzaHandler extends Handler {

  NonzaHandler({
      required this.callback,
      String? nonzaTag,
      String? nonzaXmlns,
  }) : super(
    false,
    nonzaTag: nonzaTag,
    nonzaXmlns: nonzaXmlns,
  );
  final Future<bool> Function(XMLNode) callback;
}

class StanzaHandler extends Handler {

  StanzaHandler({
      required this.callback,
      this.tagXmlns,
      this.tagName,     
      this.priority = 0,
      String? stanzaTag,
  }) : super(
      true,
      nonzaTag: stanzaTag,
      nonzaXmlns: stanzaXmlns,
    );
  final String? tagName;
  final String? tagXmlns;
  final int priority;
  final Future<StanzaHandlerData> Function(Stanza, StanzaHandlerData) callback;
    
  @override
  bool matches(XMLNode node) {
    var matches = super.matches(node);
    
    if (matches == false) {
      return false;
    }
    
    if (tagName != null) {
      final firstTag = node.firstTag(tagName!, xmlns: tagXmlns);

      matches = firstTag != null;
    } else if (tagXmlns != null) {
      return listContains(
        node.children,
        (XMLNode _node) => _node.attributes.containsKey('xmlns') && _node.attributes['xmlns'] == tagXmlns,
      );
    }

    if (tagName == null && tagXmlns == null) {
      matches = true;
    }
    
    return matches;
  }
}

int stanzaHandlerSortComparator(StanzaHandler a, StanzaHandler b) => b.priority.compareTo(a.priority);
