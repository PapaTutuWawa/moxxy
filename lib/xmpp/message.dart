import "package:moxxyv2/shared/helpers.dart";
import "package:moxxyv2/xmpp/stanza.dart";
import "package:moxxyv2/xmpp/events.dart";
import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/jid.dart";
import "package:moxxyv2/xmpp/namespaces.dart";
import "package:moxxyv2/xmpp/managers/base.dart";
import "package:moxxyv2/xmpp/managers/data.dart";
import "package:moxxyv2/xmpp/managers/namespaces.dart";
import "package:moxxyv2/xmpp/managers/handlers.dart";
import "package:moxxyv2/xmpp/xeps/xep_0085.dart";
import "package:moxxyv2/xmpp/xeps/xep_0184.dart";
import "package:moxxyv2/xmpp/xeps/xep_0333.dart";
import "package:moxxyv2/xmpp/xeps/xep_0359.dart";

class MessageDetails {
  final String to;
  final String body;
  final bool requestDeliveryReceipt;
  final bool requestChatMarkers;
  final String? id;
  final String? originId;
  final String? quoteBody;
  final String? quoteId;
  final String? quoteFrom;
  final ChatState? chatState;

  const MessageDetails({
      required this.to,
      required this.body,
      this.requestDeliveryReceipt = false,
      this.requestChatMarkers = true,
      this.id,
      this.originId,
      this.quoteBody,
      this.quoteId,
      this.quoteFrom,
      this.chatState
  });
}

class MessageManager extends XmppManagerBase {
  @override
  String getId() => messageManager;

  @override
  String getName() => "MessageManager";

  @override
  List<StanzaHandler> getIncomingStanzaHandlers() => [
    StanzaHandler(
      stanzaTag: "message",
      callback: _onMessage,
      priority: -100
    )
  ];
  
  Future<StanzaHandlerData> _onMessage(Stanza _, StanzaHandlerData state) async {
    // First check if it's a carbon
    final message = state.stanza;
    final body = message.firstTag("body");
    
    getAttributes().sendEvent(MessageEvent(
      body: body != null ? body.innerText() : "",
      fromJid: JID.fromString(message.attributes["from"]!),
      toJid: JID.fromString(message.attributes["to"]!),
      sid: message.attributes["id"]!,
      stanzaId: state.stableId ?? const StableStanzaId(),
      isCarbon: state.isCarbon,
      deliveryReceiptRequested: state.deliveryReceiptRequested,
      isMarkable: state.isMarkable,
      type: message.attributes["type"],
      oob: state.oob,
      sfs: state.sfs,
      sims: state.sims,
      reply: state.reply,
      chatState: state.chatState
    ));

    return state.copyWith(done: true);
  }

  /// Send a message to [to] with the content [body]. If [deliveryRequest] is true, then
  /// the message will also request a delivery receipt from the receiver.
  /// If [id] is non-null, then it will be the id of the message stanza.
  /// element to this id. If [originId] is non-null, then it will create an "origin-id"
  /// child in the message stanza and set its id to [originId].
  void sendMessage(MessageDetails details) {
    final stanza = Stanza.message(
      to: details.to,
      type: "chat",
      id: details.id,
      children: []
    );

    if (details.quoteBody != null) {
      final fallback = "&gt; ${details.quoteBody!}";

      stanza.addChild(
        XMLNode(tag: "body", text: fallback + "\n${details.body}")
      );
      stanza.addChild(
        XMLNode.xmlns(
          tag: "reply",
          xmlns: replyXmlns,
          attributes: {
            "to": details.quoteFrom!,
            "id": details.quoteId!
          }
        )
      );
      stanza.addChild(
        XMLNode.xmlns(
          tag: "fallback",
          xmlns: fallbackXmlns,
          attributes: {
            "for": replyXmlns
          },
          children: [
            XMLNode(
              tag: "body",
              attributes: {
                "start": "0",
                "end": "${fallback.length}"
              }
            )
          ]
        )
      );
    } else {
      stanza.addChild(
        XMLNode(tag: "body", text: details.body)
      );
    }

    if (details.requestDeliveryReceipt) {
      stanza.addChild(makeMessageDeliveryRequest());
    }
    if (details.requestChatMarkers) {
      stanza.addChild(makeChatMarkerMarkable());
    }
    if (details.originId != null) {
      stanza.addChild(makeOriginIdElement(details.originId!));
    }

    if (details.chatState != null) {
      stanza.addChild(
        // TODO: Move this into xep_0085.dart
        XMLNode.xmlns(tag: chatStateToString(details.chatState!), xmlns: chatStateXmlns)
      );
    }
    
    getAttributes().sendStanza(stanza, awaitable: false);
  }
}
