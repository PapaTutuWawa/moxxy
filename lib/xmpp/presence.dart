import "package:moxxyv2/xmpp/stanzas/stanza.dart";
import "package:moxxyv2/xmpp/managers/base.dart";
import "package:moxxyv2/xmpp/managers/namespaces.dart";
import "package:moxxyv2/xmpp/managers/handlers.dart";

class PresenceManager extends XmppManagerBase {
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
}
