import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/namespaces.dart";
import "package:moxxyv2/xmpp/stanza.dart";
import "package:moxxyv2/xmpp/managers/base.dart";
import "package:moxxyv2/xmpp/managers/namespaces.dart";
import "package:moxxyv2/xmpp/managers/handlers.dart";
import "package:moxxyv2/xmpp/xeps/xep_0030.dart";
import "package:moxxyv2/xmpp/xeps/xep_0115.dart";
import "package:moxxyv2/xmpp/xeps/xep_0414.dart";

class PresenceManager extends XmppManagerBase {
  String? _capabilityHash;
  /// A mapping of capability hashes a JID has
  final Map<String, String> _caphashCache;

  PresenceManager() : _capabilityHash = null, _caphashCache = {}, super();
  
  @override
  String getId() => presenceManager;

  @override
  List<StanzaHandler> getStanzaHandlers() => [
    StanzaHandler(
      stanzaTag: "presence",
      callback: _onPresence
    )
  ];

  @override
  List<String> getDiscoFeatures() => [ capsXmlns ];

  DiscoManager _getDiscoManager() => getAttributes().getManagerById(discoManager)! as DiscoManager;
  
  Future<bool> _onPresence(Stanza presence) async {
    final attrs = getAttributes();
    if (presence.from != null) {
      attrs.log("Received presence from '${presence.from}'");

      final caphash = presence.firstTag("c", xmlns: capsXmlns);
      if (caphash != null) {
        attrs.log("Got a capability hash");

        final manager = _getDiscoManager();
        if (!manager.knowsInfoByCapHash(caphash.attributes["ver"]!)) {
          // TODO: Maybe have a hierarchy of first checking precomputed hashes and then
          //       querying
          attrs.log("Unknown capability hash '${caphash.attributes['ver']!}'. Querying for info");
          final info = await manager.queryCaphashInfoFromJid(
            presence.from!,
            caphash.attributes["node"]!,
            caphash.attributes["ver"]!
          );

          _caphashCache[presence.from!] = caphash.attributes["ver"]!;
        }
      }
    } 

    return true;
  }

  String? getCapHashByJid(String jid) {
    return _caphashCache[jid];
  }
  
  /// Returns the capability hash.
  Future<String> getCapabilityHash() async {
    final manager = getAttributes().getManagerById(discoManager)! as DiscoManager;
    _capabilityHash ??= await calculateCapabilityHash(
      DiscoInfo(
        features: manager.getRegisteredDiscoFeatures(),
        identities: manager.getIdentities()
      ),
      getHashByName("sha-1")!
    );

    return _capabilityHash!;
  }
  
  /// Sends the initial presence to enable receiving messages.
  Future<void> sendInitialPresence() async {
    final attrs = getAttributes();
    attrs.sendStanza(Stanza.presence(
        from: attrs.getFullJID().toString(),
        children: [
          XMLNode(
            tag: "show",
            text: "chat"
          ),
          XMLNode.xmlns(
            tag: "c",
            xmlns: capsXmlns,
            attributes: {
              "hash": "sha-1",
              "node": "http://moxxy.im",
              "ver": await getCapabilityHash()
            }
          )
        ]
    ));
  }
}
