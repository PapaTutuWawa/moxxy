import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/namespaces.dart";
import "package:moxxyv2/xmpp/stanza.dart";
import "package:moxxyv2/xmpp/jid.dart";
import "package:moxxyv2/xmpp/events.dart";
import "package:moxxyv2/xmpp/managers/base.dart";
import "package:moxxyv2/xmpp/managers/namespaces.dart";
import "package:moxxyv2/xmpp/managers/handlers.dart";
import "package:moxxyv2/xmpp/xeps/xep_0030/xep_0030.dart";
import "package:moxxyv2/xmpp/xeps/xep_0030/helpers.dart";
import "package:moxxyv2/xmpp/xeps/xep_0115.dart";
import "package:moxxyv2/xmpp/xeps/xep_0414.dart";

class PresenceManager extends XmppManagerBase {
  String? _capabilityHash;

  PresenceManager() : _capabilityHash = null, super();
  
  @override
  String getId() => presenceManager;

  @override
  String getName() => "PresenceManager";

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
    final attrs = getAttributes();
    switch (presence.type) {
      case "subscribed": {
        attrs.sendEvent(SubscriptionRequestReceivedEvent(from: JID.fromString(presence.from!)));
        return true;
      }
      default: break;
    }

    if (presence.from != null) {
      logger.finest("Received presence from '${presence.from}'");

      getAttributes().sendEvent(PresenceReceivedEvent(JID.fromString(presence.from!), presence));
    } 

    return true;
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

  /// Sends a subscription request to [to].
  void sendSubscriptionRequest(String to) {
    getAttributes().sendStanza(
      Stanza.presence(
        type: "subscribe",
        to: to
      )
    );
  }

  /// Sends an unsubscription request to [to].
  void sendUnsubscriptionRequest(String to) {
    getAttributes().sendStanza(
      Stanza.presence(
        type: "unsubscribe",
        to: to
      )
    );
  }
}
