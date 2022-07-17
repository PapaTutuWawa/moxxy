import 'package:moxxyv2/xmpp/namespaces.dart';
import 'package:moxxyv2/xmpp/stringxml.dart';

class Stanza extends XMLNode {

  Stanza({ this.to, this.from, this.type, this.id, List<XMLNode> children = const [], required String tag, Map<String, String> attributes = const {} }) : super(
    tag: tag,
    attributes: <String, dynamic>{
      ...attributes,
      ...type != null ? <String, dynamic>{ 'type': type } : <String, dynamic>{},
      ...id != null ? <String, dynamic>{ 'id': id } : <String, dynamic>{},
      ...to != null ? <String, dynamic>{ 'to': to } : <String, dynamic>{},
      ...from != null ? <String, dynamic>{ 'from': from } : <String, dynamic>{},
      'xmlns': stanzaXmlns
    },
    children: children,
  );

  factory Stanza.iq({ String? to, String? from, String? type, String? id, List<XMLNode> children = const [], Map<String, String>? attributes = const {} }) {
    return Stanza(
      tag: 'iq',
      from: from,
      to: to,
      id: id,
      type: type,
      attributes: <String, String>{
        ...attributes!,
        'xmlns': stanzaXmlns
      },
      children: children,
    );
  }

  factory Stanza.presence({ String? to, String? from, String? type, String? id, List<XMLNode> children = const [], Map<String, String>? attributes = const {} }) {
    return Stanza(
      tag: 'presence',
      from: from,
      to: to,
      id: id,
      type: type,
      attributes: <String, String>{
        ...attributes!,
        'xmlns': stanzaXmlns
      },
      children: children,
    );
  }
  factory Stanza.message({ String? to, String? from, String? type, String? id, List<XMLNode> children = const [], Map<String, String>? attributes = const {} }) {
    return Stanza(
      tag: 'message',
      from: from,
      to: to,
      id: id,
      type: type,
      attributes: <String, String>{
        ...attributes!,
        'xmlns': stanzaXmlns
      },
      children: children,
    );
  }

  factory Stanza.fromXMLNode(XMLNode node) {
    return Stanza(
      to: node.attributes['to'] as String?,
      from: node.attributes['from'] as String?,
      id: node.attributes['id'] as String?,
      tag: node.tag,
      type: node.attributes['type'] as String?,
      children: node.children,
      // TODO(Unknown): Remove to, from, id, and type
      // TODO(Unknown): Not sure if this is the correct way to approach this
      attributes: node.attributes
        .map<String, String>((String key, dynamic value) {
          return MapEntry(key, value.toString());
        }),
    );
  }

  String? to;
  String? from;
  String? type;
  String? id;

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
  
  Stanza reply({ List<XMLNode> children = const [] }) {
    return copyWith(
      from: attributes['to'] as String?,
      to: attributes['from'] as String?,
      type: tag == 'iq' ? 'result' : attributes['type'] as String?,
      children: children,
    );
  }

  Stanza errorReply(String type, String condition, { String? text }) {
   return copyWith(
      from: attributes['to'] as String?,
      to: attributes['from'] as String?,
      type: 'error',
      children: [
        XMLNode(
          tag: 'error',
          attributes: <String, dynamic>{ 'type': type },
          children: [
            XMLNode.xmlns(
              tag: condition,
              xmlns: fullStanzaXmlns,
              children: text != null ?[
                XMLNode.xmlns(
                  tag: 'text',
                  xmlns: fullStanzaXmlns,
                  text: text,
                )
              ] : [],
            )
          ],
        )
      ],
    );
  }
}
