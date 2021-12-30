import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/namespaces.dart";

enum StanzaTag {
  IQ, PRESENCE
}

String stanzaTagName(StanzaTag tag) {
  switch (tag) {
    case StanzaTag.IQ: return "iq";
    case StanzaTag.PRESENCE: return "presence";
  }

  return "";
}

enum StanzaType {
  GET, SET, RESULT, ERROR
}

String stanzaTypeToString(StanzaType type) {
  switch (type) {
    case StanzaType.GET: return "get";
    case StanzaType.SET: return "set";
    case StanzaType.RESULT: return "result";
    case StanzaType.ERROR: return "error";
  }
}

class Stanza extends XMLNode {
  String? to;
  String? from;
  StanzaType? type;
  String? id;

  Stanza({ this.to, this.from, this.type, required StanzaTag stanzaTag, List<XMLNode>? children, this.id }) :super(
      tag: stanzaTagName(stanzaTag),
      attributes: {
        "xmlns": STANZA_XMLNS,
        ...(id != null ? { "id": id } : {}),
        ...(to != null ? { "to": to } : {}),
        ...(from != null ? { "from": from } : {}),
        ...(type != null ? { "type": stanzaTypeToString(type) } : {})
      },
      children: children
    );
}

class IqStanza extends Stanza {
  IqStanza({ String? to, String? from, required String id, required StanzaType type, List<XMLNode>? children }) : super(
    to: to,
    from: from,
    id: id,
    type: type,
    stanzaTag: StanzaTag.IQ,
    children: children
  );
}

enum PresenceShow {
  CHAT
}

String presenceShowString(PresenceShow show) {
  switch (show) {
    case PresenceShow.CHAT: return "show";
  }

  return "";
}

class PresenceStanza extends Stanza {
  PresenceStanza({ required String from, required PresenceShow show }) : super(
    from: from,
    stanzaTag: StanzaTag.PRESENCE,
    children: [
      XMLNode(
        tag: "show",
        attributes: {},
        children: [ RawTextNode(text: presenceShowString(show)) ]
      )
    ]
  );
}
