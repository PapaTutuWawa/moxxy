import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/namespaces.dart";
import "package:moxxyv2/xmpp/stanzas/stanza.dart";
import "package:moxxyv2/xmpp/managers/base.dart";
import "package:moxxyv2/xmpp/managers/namespaces.dart";
import "package:moxxyv2/xmpp/managers/handlers.dart";
import "package:moxxyv2/xmpp/xeps/xep_0030.dart";
import "package:moxxyv2/xmpp/xeps/xep_0115.dart";

class PresenceManager extends XmppManagerBase {
  String? _capabilityHash;

  PresenceManager() : _capabilityHash = null, super();
  
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
  
  Future<bool> _onPresence(Stanza presence) async {
    getAttributes().log("Received presence from '${presence.from ?? ''}'");

    return true;
  }

  /// Returns the capability hash.
  Future<String> getCapabilityHash() async {
    final manager = getAttributes().getManagerById(discoManager)! as DiscoManager;
    _capabilityHash ??= await calculateCapabilityHash(
      DiscoInfo(
        features: manager.getRegisteredDiscoFeatures(),
        identities: manager.getIdentities()
      )
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
