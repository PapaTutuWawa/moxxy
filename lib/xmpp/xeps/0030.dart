import "dart:collection";

import "package:moxxyv2/xmpp/stanzas/stanza.dart";
import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/namespaces.dart";
import "package:moxxyv2/xmpp/connection.dart";

class Identity {
  final String category;
  final String type;
  final String name;

  Identity({ required this.category, required this.type, required this.name });
}

class DiscoInfo {
  final List<String> features;
  final List<Identity> identities;

  DiscoInfo({ required this.features, required this.identities });
}

class DiscoItem {
  final String jid;
  final String node;
  final String? name;

  DiscoItem({ required this.jid, required this.node, required this.name });
}

Stanza buildDiscoInfoQueryStanza(String entity, String? node) {
  return Stanza.iq(to: entity, type: "get", children: [
      XMLNode.xmlns(
        tag: "query",
        xmlns: DISCO_INFO_XMLNS,
        attributes: node != null ? { "node": node } : {}
      )
  ]);
}

DiscoInfo? parseDiscoInfoResponse(XMLNode stanza) {
  final query = stanza.firstTag("query");
  if (query == null) return null;

  final error = stanza.firstTag("error");
  if (error != null && stanza.attributes["type"] == "error") {
    print("Disco Items error: " + error.toXml());
    return null;
  }
  
  final List<String> features = List.empty(growable: true);
  final List<Identity> identities = List.empty(growable: true);

  query.children.forEach((element) {
      if (element.tag == "feature") {
        features.add(element.attributes["var"]!);
      } else if (element.tag == "identity") {
        identities.add(Identity(
            category: element.attributes["category"]!,
            type: element.attributes["type"]!,
            name: element.attributes["name"]!
        ));
      } else {
        print("Unknown disco tag: " + element.tag);
      }
  });

  return DiscoInfo(
    features: features,
    identities: identities
  );
}

Stanza buildDiscoItemsQueryStanza(String entity, { String? node }) {
  return Stanza.iq(to: entity, type: "get", children: [
      XMLNode.xmlns(
        tag: "query",
        xmlns: DISCO_ITEMS_XMLNS,
        attributes: node != null ? { "node": node } : {}
      )
  ]);
}

List<DiscoItem>? parseDiscoItemsResponse(Stanza stanza) {
  final query = stanza.firstTag("query");
  if (query == null) return null;

  final error = stanza.firstTag("error");
  if (error != null && stanza.type == "error") {
    print("Disco Items error: " + error.toXml());
    return null;
  }
  
  return query.findTags("item").map((node) => DiscoItem(
      jid: node.attributes["jid"]!,
      node: node.attributes["node"]!,
      name: node.attributes["name"]
  )).toList();
}

Future<DiscoInfo?> discoInfoQuery(XmppConnection conn, String entity, { String? node}) async {
  final stanza = await conn.sendStanza(buildDiscoInfoQueryStanza(entity, node));
  return parseDiscoInfoResponse(stanza);
}

Future<List<DiscoItem>?> discoItemsQuery(XmppConnection conn, String entity, { String? node }) async {
  final stanza = await conn.sendStanza(buildDiscoItemsQueryStanza(entity, node: node));
  return parseDiscoItemsResponse(Stanza.fromXMLNode(stanza));
}

bool answerDiscoQuery(XmppConnection conn, Stanza stanza) {
  final query = stanza.firstTag("query");
  if (query == null) return false;

  if (query.attributes["node"] != null) {
    conn.sendStanza((Stanza.iq(
          to: stanza.from,
          from: stanza.to,
          id: stanza.id,
          type: "error",
          children: [
            XMLNode.xmlns(
              tag: "query",
              xmlns: query.attributes["xmlns"],
              attributes: {
                "node": query.attributes["node"]
              }
            ),
            XMLNode(
              tag: "error",
              attributes: {
                "type": "cancel"
              },
              children: [
                XMLNode.xmlns(
                  tag: "not-allowed",
                  xmlns: FULL_STANZA_XMLNS
                )
              ]
            )
          ]
        )
      )
    );
    return true;
  }

  conn.sendStanza(stanza.reply(
      children: [
        XMLNode.xmlns(
          tag: "query",
          xmlns: DISCO_INFO_XMLNS,
          children: [
            XMLNode(tag: "identity", attributes: { "category": "client", "type": "phone", "name": "Moxxy" }),
            XMLNode(tag: "feature", attributes: { "var": DISCO_INFO_XMLNS }),
            XMLNode(tag: "feature", attributes: { "var": CHAT_MARKERS_XMLNS })
          ]
        )
      ]
  ));
  return true;
}
