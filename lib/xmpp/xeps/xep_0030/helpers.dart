import 'package:moxxyv2/xmpp/jid.dart';
import 'package:moxxyv2/xmpp/namespaces.dart';
import 'package:moxxyv2/xmpp/stanza.dart';
import 'package:moxxyv2/xmpp/stringxml.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0004.dart';

class Identity {

  const Identity({ required this.category, required this.type, this.name, this.lang });
  final String category;
  final String type;
  final String? name;
  final String? lang;

  XMLNode toXMLNode() {
    return XMLNode(
      tag: 'identity',
      attributes: <String, dynamic>{
        'category': category,
        'type': type,
        'name': name,
        ...lang == null ? <String, dynamic>{} : <String, dynamic>{ 'xml:lang': lang }
      },
    );
  }
}

class DiscoInfo {

  const DiscoInfo(
    this.features,
    this.identities,
    this.extendedInfo,
    this.jid,
  );
  final List<String> features;
  final List<Identity> identities;
  final List<DataForm> extendedInfo;
  final JID jid;
}

class DiscoItem {

  const DiscoItem({ required this.jid, this.node, this.name });
  final String jid;
  final String? node;
  final String? name;
}

DiscoInfo? parseDiscoInfoResponse(XMLNode stanza) {
  final query = stanza.firstTag('query');
  if (query == null) return null;

  final error = stanza.firstTag('error');
  if (error != null && stanza.attributes['type'] == 'error') {
    //print("Disco Items error: " + error.toXml());
    return null;
  }
  
  final features = List<String>.empty(growable: true);
  final identities = List<Identity>.empty(growable: true);

  for (final element in query.children) {
    if (element.tag == 'feature') {
      features.add(element.attributes['var']! as String);
    } else if (element.tag == 'identity') {
      identities.add(Identity(
          category: element.attributes['category']! as String,
          type: element.attributes['type']! as String,
          name: element.attributes['name'] as String?,
      ),);
    } else {
      //print("Unknown disco tag: " + element.tag);
    }
  }

  return DiscoInfo(
    features,
    identities,
    query.findTags('x', xmlns: dataFormsXmlns).map(parseDataForm).toList(),
    JID.fromString(stanza.attributes['from']! as String),
  );
}

List<DiscoItem>? parseDiscoItemsResponse(Stanza stanza) {
  final query = stanza.firstTag('query');
  if (query == null) return null;

  final error = stanza.firstTag('error');
  if (error != null && stanza.type == 'error') {
    //print("Disco Items error: " + error.toXml());
    return null;
  }

  return query.findTags('item').map((node) => DiscoItem(
      jid: node.attributes['jid']! as String,
      node: node.attributes['node'] as String?,
      name: node.attributes['name'] as String?,
  ),).toList();
}

Stanza buildDiscoInfoQueryStanza(String entity, String? node) {
  return Stanza.iq(to: entity, type: 'get', children: [
      XMLNode.xmlns(
        tag: 'query',
        xmlns: discoInfoXmlns,
        attributes: node != null ? { 'node': node } : {},
      )
  ],);
}

Stanza buildDiscoItemsQueryStanza(String entity, { String? node }) {
  return Stanza.iq(to: entity, type: 'get', children: [
      XMLNode.xmlns(
        tag: 'query',
        xmlns: discoItemsXmlns,
        attributes: node != null ? { 'node': node } : {},
      )
  ],);
}
