import 'package:moxxyv2/xmpp/events.dart';
import 'package:moxxyv2/xmpp/jid.dart';
import 'package:moxxyv2/xmpp/managers/base.dart';
import 'package:moxxyv2/xmpp/managers/data.dart';
import 'package:moxxyv2/xmpp/managers/handlers.dart';
import 'package:moxxyv2/xmpp/managers/namespaces.dart';
import 'package:moxxyv2/xmpp/namespaces.dart';
import 'package:moxxyv2/xmpp/stanza.dart';
import 'package:moxxyv2/xmpp/stringxml.dart';

XMLNode makeMessageDeliveryRequest() {
  return XMLNode.xmlns(
    tag: 'request',
    xmlns: deliveryXmlns,
  );
}

XMLNode makeMessageDeliveryResponse(String id) {
  return XMLNode.xmlns(
    tag: 'received',
    xmlns: deliveryXmlns,
    attributes: { 'id': id },
  );
}

class MessageDeliveryReceiptManager extends XmppManagerBase {
  @override
  List<String> getDiscoFeatures() => [ deliveryXmlns ];

  @override
  String getName() => 'MessageDeliveryReceiptManager';

  @override
  String getId() => messageDeliveryReceiptManager;

  @override
  List<StanzaHandler> getIncomingStanzaHandlers() => [
    StanzaHandler(
      stanzaTag: 'message',
      tagName: 'received',
      tagXmlns: deliveryXmlns,
      callback: _onDeliveryReceiptReceived,
      // Before the message handler
      priority: -99,
    ),
    StanzaHandler(
      stanzaTag: 'message',
      tagName: 'request',
      tagXmlns: deliveryXmlns,
      callback: _onDeliveryRequestReceived,
      // Before the message handler
      priority: -99,
    )
  ];

  Future<StanzaHandlerData> _onDeliveryRequestReceived(Stanza message, StanzaHandlerData state) async {
    return state.copyWith(deliveryReceiptRequested: true);
  }
  
  Future<StanzaHandlerData> _onDeliveryReceiptReceived(Stanza message, StanzaHandlerData state) async {
    final received = message.firstTag('received', xmlns: deliveryXmlns)!;
    for (final item in message.children) {
      if (!['origin-id', 'stanza-id', 'delay', 'store', 'received'].contains(item.tag)) {
        logger.info("Won't handle stanza as delivery receipt because we found an '${item.tag}' element");

        return state.copyWith(done: true);
      }
    }

    getAttributes().sendEvent(
      DeliveryReceiptReceivedEvent(
        from: JID.fromString(message.attributes['from']! as String),
        id: received.attributes['id']! as String,
      ),
    );
    return state.copyWith(done: true);
  }
}
