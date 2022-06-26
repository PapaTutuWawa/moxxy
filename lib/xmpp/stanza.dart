import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/namespaces.dart";

class Stanza extends XMLNode {
  String? to;
  String? from;
  String? type;
  String? id;

  Stanza({ this.to, this.from, this.type, this.id, List<XMLNode> children = const [], required String tag, Map<String, String> attributes = const {} }) : super(
    tag: tag,
    attributes: {
      ...attributes,
      ...(type != null ? { "type": type } : {}),
      ...(id != null ? { "id": id } : {}),
      ...(to != null ? { "to": to } : {}),
      ...(from != null ? { "from": from } : {}),
      "xmlns": stanzaXmlns
    },
    children: children
  );

  static Stanza iq({ String? to, String? from, String? type, String? id, List<XMLNode> children = const [], Map<String, String>? attributes = const {} }) {
    return Stanza(
      tag: "iq",
      from: from,
      to: to,
      id: id,
      type: type,
      attributes: {
        ...attributes!,
        "xmlns": stanzaXmlns
      },
      children: children
    );
  }

  static Stanza presence({ String? to, String? from, String? type, String? id, List<XMLNode> children = const [], Map<String, String>? attributes = const {} }) {
    return Stanza(
      tag: "presence",
      from: from,
      to: to,
      id: id,
      type: type,
      attributes: {
        ...attributes!,
        "xmlns": stanzaXmlns
      },
      children: children
    );
  }
  static Stanza message({ String? to, String? from, String? type, String? id, List<XMLNode> children = const [], Map<String, String>? attributes = const {} }) {
    return Stanza(
      tag: "message",
      from: from,
      to: to,
      id: id,
      type: type,
      attributes: {
        ...attributes!,
        "xmlns": stanzaXmlns
      },
      children: children
    );
  }

  Stanza copyWith({ String? id, String? from, String? to, String? type, List<XMLNode>? children }) {
    return Stanza(
      tag: tag,
      to: to ?? this.to,
      from: from ?? this.from,
      id: id ?? this.id,
      type: type ?? this.type,
      children: children ?? this.children,
    );
  }

  static Stanza fromXMLNode(XMLNode node) {
    return Stanza(
      to: node.attributes["to"],
      from: node.attributes["from"],
      id: node.attributes["id"],
      tag: node.tag,
      type: node.attributes["type"],
      children: node.children,
      // TODO: Remove to, from, id, and type
      // TODO: Not sure if this is the correct way to approach this
      attributes: node.attributes.map<String, String>((key, value) => MapEntry(key, value.toString()))
    );
  }
  
  Stanza reply({ List<XMLNode> children = const [] }) {
    return copyWith(
      from: attributes["to"],
      to: attributes["from"],
      type: tag == "iq" ? "result" : attributes["type"],
      children: children
    );
  }

  Stanza errorReply(String type, String condition, { String? text }) {
   return copyWith(
      from: attributes["to"],
      to: attributes["from"],
      type: "error",
      children: [
        XMLNode(
          tag: "error",
          attributes: { "type": type },
          children: [
            XMLNode.xmlns(
              tag: condition,
              xmlns: fullStanzaXmlns,
              children: text != null ?[
                XMLNode.xmlns(
                  tag: "text",
                  xmlns: fullStanzaXmlns,
                  text: text
                )
              ] : []
            )
          ]
        )
      ]
    );
  }
}
