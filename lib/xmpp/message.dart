import "package:moxxyv2/xmpp/stanza.dart";
import "package:moxxyv2/xmpp/events.dart";
import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/jid.dart";
import "package:moxxyv2/xmpp/namespaces.dart";
import "package:moxxyv2/xmpp/managers/base.dart";
import "package:moxxyv2/xmpp/managers/namespaces.dart";
import "package:moxxyv2/xmpp/managers/handlers.dart";

class MessageManager extends XmppManagerBase {
  @override
  String getId() => messageManager;

  @override
  String getName() => "MessageManager";

  @override
  List<StanzaHandler> getStanzaHandlers() => [
    StanzaHandler(
      stanzaTag: "message",
      callback: _onMessage
    )
  ];

  @override
  List<String> getDiscoFeatures() => [ chatMarkersXmlns ];
  
  void _handleChatMarker(Stanza message, XMLNode marker) {
    final attrs = getAttributes();

    if (!["received", "displayed", "acknowledged"].contains(marker.tag)) {
      logger.warning("Unknown message marker '${marker.tag}' found.");
      return;
    }

    attrs.sendEvent(ChatMarkerEvent(
        type: marker.tag,
        sid: message.id! // TODO: Also recognise Unique and Stable IDs
    ));
  }
  
  Future<bool> _onMessage(Stanza message) async {
    final body = message.firstTag("body");
    if (body == null) {
      final marker = message.firstTagByXmlns(chatMarkersXmlns);
      if (marker != null) {
        // Response to a marker
        _handleChatMarker(message, marker);
      }

      return true;
    }

    getAttributes().sendEvent(MessageEvent(
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
