import "package:moxxyv2/xmpp/events.dart";
import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/stanza.dart";
import "package:moxxyv2/xmpp/namespaces.dart";
import "package:moxxyv2/xmpp/jid.dart";
import "package:moxxyv2/xmpp/managers/base.dart";
import "package:moxxyv2/xmpp/managers/data.dart";
import "package:moxxyv2/xmpp/managers/namespaces.dart";
import "package:moxxyv2/xmpp/managers/handlers.dart";

enum ChatState {
  active,
  composing,
  paused,
  inactive,
  gone
}

class ChatStateManager extends XmppManagerBase {
  @override
  List<String> getDiscoFeatures() => [ chatStateXmlns ];

  @override
  String getName() => "ChatStateManager";

  @override
  String getId() => chatStateManager;

  @override
  List<StanzaHandler> getIncomingStanzaHandlers() => [
    StanzaHandler(
      stanzaTag: "message",
      tagXmlns: chatStateXmlns,
      callback: _onChatStateReceived,
      // Before the message handler
      priority: -99
    )
  ];

  Future<StanzaHandlerData> _onChatStateReceived(Stanza message, StanzaHandlerData state) async {
    final element = state.stanza.firstTagByXmlns(chatStateXmlns)!;
    ChatState? chatState;

    switch (element.tag) {
      case "active": {
        chatState = ChatState.active;
      }
      break;
      case "composing": {
        chatState = ChatState.composing;
      }
      break;
      case "paused": {
        chatState = ChatState.paused;
      }
      break;
      case "inactive": {
        chatState = ChatState.inactive;
      }
      break;
      case "gone": {
        chatState = ChatState.gone;
      }
      break;
      default: {
        logger.warning("Received invalid chat state '${element.tag}'");
      }
    }

    return state.copyWith(chatState: chatState);
  }
}
