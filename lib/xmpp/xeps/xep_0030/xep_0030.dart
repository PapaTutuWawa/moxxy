import "package:moxxyv2/xmpp/stanza.dart";
import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/namespaces.dart";
import "package:moxxyv2/xmpp/connection.dart";
import "package:moxxyv2/xmpp/presence.dart";
import "package:moxxyv2/xmpp/managers/base.dart";
import "package:moxxyv2/xmpp/managers/namespaces.dart";
import "package:moxxyv2/xmpp/managers/handlers.dart";
import "package:moxxyv2/xmpp/xeps/xep_0030/helpers.dart";

class DiscoManager extends XmppManagerBase {
  /// Our features
  final List<String> _features;
  /// Mapping of CapHash -> Features. NOTE: We assume that hashes don't collide across
  /// algorithms which is a terrible assumption.
  final Map<String, DiscoInfo> _caphashInfoCache;
  /// Mapping of Full JID to disco info. Only for when an entity does not support XEP-0115
  final Map<String, DiscoInfo> _jidInfoCache;
 
  DiscoManager() : _features = List.empty(growable: true), _caphashInfoCache = {}, _jidInfoCache = {}, super();
  
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

  @override
  String getName() => "DiscoManager";

  @override
  List<String> getDiscoFeatures() => [ discoInfoXmlns, discoItemsXmlns ];

  /// Adds a list of features to the possible disco info response.
  /// This function only adds features that are not already present in the disco features.
  void addDiscoFeatures(List<String> features) {
    for (var feat in features) {
      if (!_features.contains(feat)) {
        _features.add(feat);
      }
    }
  }

  /// Returns the list of disco features registered.
  List<String> getRegisteredDiscoFeatures() => _features;
  
  /// May be overriden. Specifies the identities which will be returned in a disco info response.
  List<Identity> getIdentities() => const [ Identity(category: "client", type: "pc", name: "moxxmpp", lang: "en") ];
  
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
              ...(getIdentities().map((identity) => identity.toXMLNode()).toList()),
              ...(_features.map((feat) => XMLNode(tag: "feature", attributes: { "var": feat })).toList())
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

  bool knowsInfoByCapHash(String hash) => _caphashInfoCache.containsKey(hash);
  bool knowsInfoByJid(String jid) => _jidInfoCache.containsKey(jid);

  /// Queries information about a jid based on its node and capability hash. Caches these
  /// values.
  Future<DiscoInfo?> queryCaphashInfoFromJid(String jid, String node, String hash) async {
    // TODO: Handle error
    final info = (await discoInfoQuery(jid, node: node + "#" + hash))!;

    // TODO: Verify the hash
    
    _caphashInfoCache[hash] = info;
    _jidInfoCache[jid] = info;
    
    return info;
  }

  DiscoInfo? getInfoByHash(String hash) {
    return _caphashInfoCache[hash];
  }
  
  Future<DiscoInfo?> getInfoByJid(String jid) async {
    if (knowsInfoByJid(jid)) {
      return _jidInfoCache[jid]!;
    }

    final presence = getAttributes().getManagerById(presenceManager)! as PresenceManager;
    final hash = presence.getCapHashByJid(jid);
    if (hash != null) {
      if (knowsInfoByCapHash(hash)) {
        return _caphashInfoCache[hash]!;
      }

      // TODO: Query jid and cache hash
    }

    // TODO: Error handling
    final info = (await discoInfoQuery(jid))!;
    _jidInfoCache[jid] = info;

    return info;
  }
}
