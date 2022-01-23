import "package:moxxyv2/xmpp/stanzas/stanza.dart";
import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/namespaces.dart";
import "package:moxxyv2/xmpp/connection.dart";
import "package:moxxyv2/xmpp/presence.dart";
import "package:moxxyv2/xmpp/managers/base.dart";
import "package:moxxyv2/xmpp/managers/namespaces.dart";
import "package:moxxyv2/xmpp/managers/handlers.dart";

// TODO: Factor out of lib/xmpp. Maybe have managers register their supported xmlns?
const discoFeatures = [
  discoInfoXmlns, discoItemsXmlns,
  chatMarkersXmlns,
  capsXmlns
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

DiscoInfo? parseDiscoInfoResponse(XMLNode stanza) {
  final query = stanza.firstTag("query");
  if (query == null) return null;

  final error = stanza.firstTag("error");
  if (error != null && stanza.attributes["type"] == "error") {
    //print("Disco Items error: " + error.toXml());
    return null;
  }
  
  final List<String> features = List.empty(growable: true);
  final List<Identity> identities = List.empty(growable: true);

  for (var element in query.children) {
    if (element.tag == "feature") {
      features.add(element.attributes["var"]!);
    } else if (element.tag == "identity") {
      identities.add(Identity(
          category: element.attributes["category"]!,
          type: element.attributes["type"]!,
          name: element.attributes["name"]!
      ));
    } else {
      //print("Unknown disco tag: " + element.tag);
    }
  }

  // TODO: Include extendedInfo
  return DiscoInfo(
    features: features,
    identities: identities
  );
}

List<DiscoItem>? parseDiscoItemsResponse(Stanza stanza) {
  final query = stanza.firstTag("query");
  if (query == null) return null;

  final error = stanza.firstTag("error");
  if (error != null && stanza.type == "error") {
    //print("Disco Items error: " + error.toXml());
    return null;
  }

  // TODO: Include extendedInfo
  return query.findTags("item").map((node) => DiscoItem(
      jid: node.attributes["jid"]!,
      node: node.attributes["node"]!,
      name: node.attributes["name"]
  )).toList();
}

class DiscoManager extends XmppManagerBase {
  @override
  List<StanzaHandler> getStanzaHandlers() => [
    StanzaHandler(
      tagName: "query",
      tagXmlns: discoInfoXmlns,
      stanzaTag: "iq",
      callback: _onDiscoInfoRequest
    ),
    StanzaHandler(
      tagName: "query",
      tagXmlns: discoItemsXmlns,
      stanzaTag: "iq",
      callback: _onDiscoItemsRequest
    ),
  ];

  @override
  String getId() => discoManager;
  
  Future<bool> _onDiscoInfoRequest(Stanza stanza) async {
    final presence = getAttributes().getManagerById(presenceManager)! as PresenceManager;
    final query = stanza.firstTag("query")!;
    final node = query.attributes["node"];
    final capHash = await presence.getCapabilityHash();
    final isCapabilityNode = node == "http://moxxy.im#" + capHash;

    if (!isCapabilityNode && node != null) {
      getAttributes().sendStanza((Stanza.iq(
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
                    xmlns: fullStanzaXmlns
                  )
                ]
              )
            ]
          )
      ));

      return true;
    }

    getAttributes().sendStanza(stanza.reply(
        children: [
          XMLNode.xmlns(
            tag: "query",
            xmlns: discoInfoXmlns,
            attributes: {
              ...(!isCapabilityNode ? {} : {
                  "node": "http://moxxy.im#" + capHash
              })
            },
            children: [
              XMLNode(tag: "identity", attributes: { "category": "client", "type": "phone", "name": "Moxxy" }),

              ...(discoFeatures.map((feat) => XMLNode(tag: "feature", attributes: { "var": feat })).toList())
            ]
          )
        ]
    ));

    return true;
  }

  Future<bool> _onDiscoItemsRequest(Stanza stanza) async {
    final query = stanza.firstTag("query")!;
    if (query.attributes["node"] != null) {
      // TODO: Handle the node we specified for XEP-0115
      getAttributes().sendStanza((Stanza.iq(
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
                    xmlns: fullStanzaXmlns
                  )
                ]
              )
            ]
          )
      ));

      return true;
    }

    getAttributes().sendStanza(stanza.reply(
        children: [
          XMLNode.xmlns(
            tag: "query",
            xmlns: discoItemsXmlns
          )
        ]
    ));
    return true;
  }

  /// Sends a disco info query to the (full) jid [entity], optionally with node=[node].
  Future<DiscoInfo?> discoInfoQuery(String entity, { String? node}) async {
    final stanza = await getAttributes().sendStanza(buildDiscoInfoQueryStanza(entity, node));
    return parseDiscoInfoResponse(stanza);
  }

  /// Sends a disco items query to the (full) jid [entity], optionally with node=[node].
  Future<List<DiscoItem>?> discoItemsQuery(XmppConnection conn, String entity, { String? node }) async {
    final stanza = await getAttributes().sendStanza(buildDiscoItemsQueryStanza(entity, node: node));
    return parseDiscoItemsResponse(Stanza.fromXMLNode(stanza));
  }
}

Stanza buildDiscoInfoQueryStanza(String entity, String? node) {
  return Stanza.iq(to: entity, type: "get", children: [
      XMLNode.xmlns(
        tag: "query",
        xmlns: discoInfoXmlns,
        attributes: node != null ? { "node": node } : {}
      )
  ]);
}

Stanza buildDiscoItemsQueryStanza(String entity, { String? node }) {
  return Stanza.iq(to: entity, type: "get", children: [
      XMLNode.xmlns(
        tag: "query",
        xmlns: discoItemsXmlns,
        attributes: node != null ? { "node": node } : {}
      )
  ]);
}
