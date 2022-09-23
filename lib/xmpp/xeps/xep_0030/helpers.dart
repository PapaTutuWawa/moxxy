import 'package:moxxyv2/xmpp/namespaces.dart';
import 'package:moxxyv2/xmpp/stanza.dart';
import 'package:moxxyv2/xmpp/stringxml.dart';

// TODO(PapaTutuWawa): Move types into types.dart

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
