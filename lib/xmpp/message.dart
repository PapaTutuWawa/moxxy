import "package:moxxyv2/xmpp/stanzas/stanza.dart";
import "package:moxxyv2/xmpp/connection.dart";
import "package:moxxyv2/xmpp/events.dart";
import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/jid.dart";
import "package:moxxyv2/xmpp/managers/base.dart";
import "package:moxxyv2/xmpp/managers/namespaces.dart";
import "package:moxxyv2/xmpp/managers/handlers.dart";

class MessageManager extends XmppManagerBase {
  @override
  String getId() => MESSAGE_MANAGER;

  @override
  List<StanzaHandler> getStanzaHandlers() => [
    StanzaHandler(
      stanzaTag: "message",
      callback: this._onMessage
    )
  ];

  bool _onMessage(Stanza message) {
    final body = message.firstTag("body");
    if (body == null) return true;

    this.getAttributes().sendEvent(MessageEvent(
      body: body.innerText(),
      fromJid: FullJID.fromString(message.attributes["from"]!),
      sid: message.attributes["id"]!
    ));

    return true;
  }

  /// Send a message to [to] with the content [body].
  void sendMessage(String body, String to) {
    getAttributes().sendStanza(Stanza.message(
        to: to,
        type: "normal",
        children: [
          XMLNode(tag: "body", text: body)
        ]
    ));
  }
}
