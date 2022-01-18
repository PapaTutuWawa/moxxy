import "dart:collection";

import "package:moxxyv2/xmpp/stanzas/stanza.dart";
import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/namespaces.dart";
import "package:moxxyv2/xmpp/connection.dart";

const DISCO_FEATURES = [
  DISCO_INFO_XMLNS, DISCO_ITEMS_XMLNS,
  CHAT_MARKERS_XMLNS,
  CAPS_XMLNS
];

class Identity {
  final String category;
  final String type;
  final String name;
  final String? lang;

  Identity({ required this.category, required this.type, required this.name, this.lang });
}

class DiscoInfo {
  final List<String> features;
  final List<Identity> identities;
  final Map<String, List<String>>? extendedInfo;

  DiscoInfo({ required this.features, required this.identities, this.extendedInfo });
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

bool answerDiscoItemsQuery(XmppConnection conn, Stanza stanza) {
  final query = stanza.firstTag("query")!;
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

  conn.sendStanza(stanza.reply(children: [
        XMLNode.xmlns(tag: "query", xmlns: DISCO_ITEMS_XMLNS)
  ]));
  return true;
}

bool answerDiscoInfoQuery(XmppConnection conn, Stanza stanza) {
  final query = stanza.firstTag("query")!;
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

  // TODO: Answer for node="http://moxxy.im#<capHash>"
  conn.sendStanza(stanza.reply(
      children: [
        XMLNode.xmlns(
          tag: "query",
          xmlns: DISCO_INFO_XMLNS,
          children: [
            XMLNode(tag: "identity", attributes: { "category": "client", "type": "phone", "name": "Moxxy" }),

            ...(DISCO_FEATURES.map((feat) => XMLNode(tag: "feature", attributes: { "var": feat })).toList())
          ]
        )
      ]
  ));
  return true;
}
