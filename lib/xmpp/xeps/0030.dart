import "dart:collection";

import "package:moxxyv2/xmpp/stanzas/stanza.dart";
import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/namespaces.dart";
import "package:moxxyv2/xmpp/connection.dart";
import "package:moxxyv2/xmpp/presence.dart";
import "package:moxxyv2/xmpp/managers/base.dart";
import "package:moxxyv2/xmpp/managers/namespaces.dart";
import "package:moxxyv2/xmpp/managers/handlers.dart";

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
    print("Disco Items error: " + error.toXml());
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
      tagXmlns: DISCO_INFO_XMLNS,
      stanzaTag: "iq",
      callback: this._onDiscoInfoRequest
    ),
    StanzaHandler(
      tagName: "query",
      tagXmlns: DISCO_ITEMS_XMLNS,
      stanzaTag: "iq",
      callback: this._onDiscoItemsRequest
    ),
  ];

  @override
  String getId() => DISCO_MANAGER;
  
  bool _onDiscoInfoRequest(Stanza stanza) {
    // TODO: Maybe make all callbacks async
    (() async {
        final presenceManager = getAttributes().getManagerById(PRESENCE_MANAGER)! as PresenceManager;
        final query = stanza.firstTag("query")!;
        final node = query.attributes["node"];
        final capHash = await presenceManager.getCapabilityHash();
        final isCapabilityNode = node == "http://moxxy.im#" + capHash;

        if (!isCapabilityNode && node != null) {
          this.getAttributes().sendStanza((Stanza.iq(
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
          ));

          return true;
        }

        this.getAttributes().sendStanza(stanza.reply(
            children: [
              XMLNode.xmlns(
                tag: "query",
                xmlns: DISCO_INFO_XMLNS,
                attributes: {
                  ...(!isCapabilityNode ? {} : {
                      "node": "http://moxxy.im#" + capHash
                  })
                },
                children: [
                  XMLNode(tag: "identity", attributes: { "category": "client", "type": "phone", "name": "Moxxy" }),

                  ...(DISCO_FEATURES.map((feat) => XMLNode(tag: "feature", attributes: { "var": feat })).toList())
                ]
              )
            ]
        ));
    })();

    return true;
  }

  bool _onDiscoItemsRequest(Stanza stanza) {
    final query = stanza.firstTag("query")!;
    if (query.attributes["node"] != null) {
      // TODO: Handle the node we specified for XEP-0115
      this.getAttributes().sendStanza((Stanza.iq(
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
      ));

      return true;
    }

    this.getAttributes().sendStanza(stanza.reply(
        children: [
          XMLNode.xmlns(
            tag: "query",
            xmlns: DISCO_ITEMS_XMLNS
          )
        ]
    ));
    return true;
  }

  /// Sends a disco info query to the (full) jid [entity], optionally with node=[node].
  Future<DiscoInfo?> discoInfoQuery(String entity, { String? node}) async {
    final stanza = await this.getAttributes().sendStanza(buildDiscoInfoQueryStanza(entity, node));
    return parseDiscoInfoResponse(stanza);
  }

  /// Sends a disco items query to the (full) jid [entity], optionally with node=[node].
  Future<List<DiscoItem>?> discoItemsQuery(XmppConnection conn, String entity, { String? node }) async {
    final stanza = await this.getAttributes().sendStanza(buildDiscoItemsQueryStanza(entity, node: node));
    return parseDiscoItemsResponse(Stanza.fromXMLNode(stanza));
  }
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

Stanza buildDiscoItemsQueryStanza(String entity, { String? node }) {
  return Stanza.iq(to: entity, type: "get", children: [
      XMLNode.xmlns(
        tag: "query",
        xmlns: DISCO_ITEMS_XMLNS,
        attributes: node != null ? { "node": node } : {}
      )
  ]);
}
