import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/namespaces.dart";
import "package:moxxyv2/xmpp/stanzas/stanza.dart";
import "package:moxxyv2/xmpp/managers/base.dart";
import "package:moxxyv2/xmpp/managers/namespaces.dart";
import "package:moxxyv2/xmpp/managers/handlers.dart";
import "package:moxxyv2/xmpp/xeps/0030.dart";
import "package:moxxyv2/xmpp/xeps/0115.dart";

class PresenceManager extends XmppManagerBase {
  String? _capabilityHash;

  PresenceManager() : _capabilityHash = null, super();
  
  @override
  String getId() => PRESENCE_MANAGER;

  @override
  List<StanzaHandler> getStanzaHandlers() => [
    StanzaHandler(
      stanzaTag: "presence",
      callback: this._onPresence
    )
  ];

  bool _onPresence(Stanza presence) {
    this.getAttributes().log("Received presence from '${presence.from ?? ''}'");

    return true;
  }
  
  /// Sends the initial presence to enable receiving messages.
  Future<void> sendInitialPresence() async {
    // TODO: Maybe factor this out
    if (_capabilityHash == null) {
      _capabilityHash = await calculateCapabilityHash(
        DiscoInfo(
          features: DISCO_FEATURES,
          identities: [
            Identity(
              category: "client",
              type: "phone",
              name: "Moxxy"
            )
          ]
        )
      );
    }

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
            xmlns: CAPS_XMLNS,
            attributes: {
              "hash": "sha-1",
              "node": "http://moxxy.im",
              "ver": _capabilityHash!
            }
          )
        ]
    ));
  }
}
