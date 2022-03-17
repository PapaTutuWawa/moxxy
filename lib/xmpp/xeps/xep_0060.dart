import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/namespaces.dart";
import "package:moxxyv2/xmpp/stanza.dart";
import "package:moxxyv2/xmpp/events.dart";
import "package:moxxyv2/xmpp/xeps/xep_0004.dart";
import "package:moxxyv2/xmpp/managers/base.dart";
import "package:moxxyv2/xmpp/managers/data.dart";
import "package:moxxyv2/xmpp/managers/namespaces.dart";
import "package:moxxyv2/xmpp/managers/handlers.dart";

class PubSubPublishOptions {
  final String? accessModel;

  const PubSubPublishOptions({
      this.accessModel
  });
  
  XMLNode toXml() {
    return DataForm(
      type: "submit",
      instructions: [],
      reported: [],
      items: [],
      fields: [
        const DataFormField(
          options: [],
          isRequired: false,
          values: [ pubsubPublishOptionsXmlns ],
          varAttr: "FORM_TYPE",
          type: "hidden"
        ),
        ...(accessModel != null ? [
            DataFormField(
              options: [],
              isRequired: false,
              values: [ accessModel! ],
              varAttr: "pubsub#access_model",
            )
          ] : [])
      ]
    ).toXml();
  }
}

class PubSubItem {
  final String id;
  final String node;
  final XMLNode payload;

  const PubSubItem({ required this.id, required this.node, required this.payload });

  @override
  String toString() => "$id: ${payload.toXml()}";
}

class PubSubManager extends XmppManagerBase {
  @override
  String getId() => pubsubManager;

  @override
  String getName() => "PubsubManager";

  @override
  List<StanzaHandler> getIncomingStanzaHandlers() => [
    StanzaHandler(
      stanzaTag: "message",
      tagName: "event",
      tagXmlns: pubsubEventXmlns,
      callback: _onPubsubMessage
    )
  ];

  Future<StanzaHandlerData> _onPubsubMessage(Stanza message, StanzaHandlerData state) async {
    logger.finest("Received PubSub event");
    final event = message.firstTag("event", xmlns: pubsubEventXmlns)!;
    final items = event.firstTag("items")!;
    final item = items.firstTag("item")!;

    getAttributes().sendEvent(PubSubNotificationEvent(
        item: PubSubItem(
          id: item.attributes["id"]!,
          node: items.attributes["node"]!,
          payload: item.children[0]
        ),
        from: message.attributes["from"]!
    ));
    
    return state.copyWith(done: true);
  }
  
  Future<bool> subscribe(String jid, String node) async {
    final attrs = getAttributes();
    final result = await attrs.sendStanza(
      Stanza.iq(
        type: "set",
        to: jid,
        children: [
          XMLNode.xmlns(
            tag: "pubsub",
            xmlns: pubsubXmlns,
            children: [
              XMLNode(
                tag: "subscribe",
                attributes: {
                  "node": node,
                  "jid": attrs.getFullJID().toBare().toString()
                }
              )
            ]
          )
        ]
      )
    );

    if (result.attributes["type"] != "result") return false;

    final pubsub = result.firstTag("pubsub", xmlns: pubsubXmlns);
    if (pubsub == null) return false;

    final subscription = pubsub.firstTag("subscription");
    if (subscription == null) return false;

    return subscription.attributes["subscription"] == "subscribed";
  }

  Future<bool> unsubscribe(String jid, String node) async {
    final attrs = getAttributes();
    final result = await attrs.sendStanza(
      Stanza.iq(
        type: "set",
        to: jid,
        children: [
          XMLNode.xmlns(
            tag: "pubsub",
            xmlns: pubsubXmlns,
            children: [
              XMLNode(
                tag: "unsubscribe",
                attributes: {
                  "node": node,
                  "jid": attrs.getFullJID().toBare().toString()
                }
              )
            ]
          )
        ]
      )
    );

    if (result.attributes["type"] != "result") return false;

    final pubsub = result.firstTag("pubsub", xmlns: pubsubXmlns);
    if (pubsub == null) return false;

    final subscription = pubsub.firstTag("subscription");
    if (subscription == null) return false;

    return subscription.attributes["subscription"] == "none";
  }

  /// Publish [payload] to the PubSub node [node] on JID [jid]. Returns true if it
  /// was successful. False otherwise.
  Future<bool> publish(String jid, String node, XMLNode payload, { String? id, PubSubPublishOptions? options }) async {
    final result = await getAttributes().sendStanza(
      Stanza.iq(
        type: "set",
        to: jid,
        children: [
          XMLNode.xmlns(
            tag: "pubsub",
            xmlns: pubsubXmlns,
            children: [
              XMLNode(
                tag: "publish",
                attributes: { "node": node },
                children: [
                  XMLNode(
                    tag: "item",
                    attributes: id != null ? { "id": id } : {},
                    children: [ payload ]
                  )
                ]
              ),
              ...(options != null ? [ options.toXml() ] : [])
            ]
          )
        ]
      )
    );

    if (result.attributes["type"] != "result") return false;

    final pubsub = result.firstTag("pubsub", xmlns: pubsubXmlns);
    if (pubsub == null) return false;

    final publish = pubsub.firstTag("publish");
    if (publish == null) return false;

    final item = publish.firstTag("item");
    if (item == null) return false;

    if (id != null) return item.attributes["id"] == id;

    return true;
  }
  
  Future<List<PubSubItem>?> getItems(String jid, String node) async {
    final result = await getAttributes().sendStanza(
      Stanza.iq(
        type: "get",
        to: jid,
        children: [
          XMLNode.xmlns(
            tag: "pubsub",
            xmlns: pubsubXmlns,
            children: [ XMLNode(tag: "items", attributes: { "node": node }) ]
          )
        ]
      )
    );

    if (result.attributes["type"] != "result") return null;

    final pubsub = result.firstTag("pubsub", xmlns: pubsubXmlns);
    if (pubsub == null) return null;

    return pubsub.firstTag("items")!.children.map((item) => PubSubItem(
        id: item.attributes["id"],
        payload: item.children[0],
        node: node
    )).toList();
  }
}
