import "package:moxxyv2/xmpp/events.dart";
import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/stanza.dart";
import "package:moxxyv2/xmpp/namespaces.dart";
import "package:moxxyv2/xmpp/jid.dart";
import "package:moxxyv2/xmpp/managers/base.dart";
import "package:moxxyv2/xmpp/managers/data.dart";
import "package:moxxyv2/xmpp/managers/namespaces.dart";
import "package:moxxyv2/xmpp/managers/handlers.dart";

XMLNode makeChatMarkerMarkable() {
  return XMLNode.xmlns(
    tag: "markable",
    xmlns: chatMarkersXmlns
  );
}

XMLNode makeChatMarker(String tag, String id) {
  assert(["received", "displayed", "acknowledged"].contains(tag));
  return XMLNode.xmlns(
    tag: tag,
    xmlns: chatMarkersXmlns,
    attributes: { "id": id }
  );
}

class ChatMarkerManager extends XmppManagerBase {
  @override
  String getName() => "ChatMarkerManager";

  @override
  String getId() => chatMarkerManager;

  @override
  List<String> getDiscoFeatures() => [ chatMarkersXmlns ];

  @override
  List<StanzaHandler> getIncomingStanzaHandlers() => [
    StanzaHandler(
      stanzaTag: "message",
      tagXmlns: chatMarkersXmlns,
      callback: _onMessage,
      // Before the message handler
      priority: -99,
    )
  ];

  Future<StanzaHandlerData> _onMessage(Stanza message, StanzaHandlerData state) async {
    final marker = message.firstTagByXmlns(chatMarkersXmlns)!;

    // Handle the <markable /> explicitly
    if (marker.tag == "markable") return state.copyWith(isMarkable: true);
    
    if (!["received", "displayed", "acknowledged"].contains(marker.tag)) {
      logger.warning("Unknown message marker '${marker.tag}' found.");
    } else {
      getAttributes().sendEvent(ChatMarkerEvent(
          from: JID.fromString(message.from!),
          type: marker.tag,
          id: marker.attributes["id"]!,
      ));
    }

    return state.copyWith(done: true);
  }
}
