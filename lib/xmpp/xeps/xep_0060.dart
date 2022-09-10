import 'package:moxxyv2/xmpp/events.dart';
import 'package:moxxyv2/xmpp/managers/base.dart';
import 'package:moxxyv2/xmpp/managers/data.dart';
import 'package:moxxyv2/xmpp/managers/handlers.dart';
import 'package:moxxyv2/xmpp/managers/namespaces.dart';
import 'package:moxxyv2/xmpp/namespaces.dart';
import 'package:moxxyv2/xmpp/stanza.dart';
import 'package:moxxyv2/xmpp/stringxml.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0004.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0030/xep_0030.dart';

const pubsubNodeConfigMax = 'http://jabber.org/protocol/pubsub#config-node-max';

class PubSubPublishOptions {

  const PubSubPublishOptions({
    this.accessModel,
    this.maxItems,
  });
  final String? accessModel;
  final String? maxItems;
  
  XMLNode toXml() {
    return DataForm(
      type: 'submit',
      instructions: [],
      reported: [],
      items: [],
      fields: [
        const DataFormField(
          options: [],
          isRequired: false,
          values: [ pubsubPublishOptionsXmlns ],
          varAttr: 'FORM_TYPE',
          type: 'hidden',
        ),
        ...accessModel != null ? [
            DataFormField(
              options: [],
              isRequired: false,
              values: [ accessModel! ],
              varAttr: 'pubsub#access_model',
            )
          ] : [],
        ...maxItems != null ? [
          DataFormField(
            options: [],
            isRequired: false,
            values: [maxItems! ],
            varAttr: 'pubsub#max_items',
          ),
        ] : [],
      ],
    ).toXml();
  }
}

class PubSubItem {

  const PubSubItem({ required this.id, required this.node, required this.payload });
  final String id;
  final String node;
  final XMLNode payload;

  @override
  String toString() => '$id: ${payload.toXml()}';
}

class PubSubManager extends XmppManagerBase {
  @override
  String getId() => pubsubManager;

  @override
  String getName() => 'PubsubManager';

  @override
  List<StanzaHandler> getIncomingStanzaHandlers() => [
    StanzaHandler(
      stanzaTag: 'message',
      tagName: 'event',
      tagXmlns: pubsubEventXmlns,
      callback: _onPubsubMessage,
    )
  ];

  @override
  Future<bool> isSupported() async => true;

  Future<StanzaHandlerData> _onPubsubMessage(Stanza message, StanzaHandlerData state) async {
    logger.finest('Received PubSub event');
    final event = message.firstTag('event', xmlns: pubsubEventXmlns)!;
    final items = event.firstTag('items')!;
    final item = items.firstTag('item')!;

    getAttributes().sendEvent(PubSubNotificationEvent(
      item: PubSubItem(
        id: item.attributes['id']! as String,
        node: items.attributes['node']! as String,
        payload: item.children[0],
      ),
      from: message.attributes['from']! as String,
    ),);
    
    return state.copyWith(done: true);
  }
  
  Future<bool> subscribe(String jid, String node) async {
    final attrs = getAttributes();
    final result = await attrs.sendStanza(
      Stanza.iq(
        type: 'set',
        to: jid,
        children: [
          XMLNode.xmlns(
            tag: 'pubsub',
            xmlns: pubsubXmlns,
            children: [
              XMLNode(
                tag: 'subscribe',
                attributes: <String, String>{
                  'node': node,
                  'jid': attrs.getFullJID().toBare().toString(),
                },
              ),
            ],
          ),
        ],
      ),
    );

    if (result.attributes['type'] != 'result') return false;

    final pubsub = result.firstTag('pubsub', xmlns: pubsubXmlns);
    if (pubsub == null) return false;

    final subscription = pubsub.firstTag('subscription');
    if (subscription == null) return false;

    return subscription.attributes['subscription'] == 'subscribed';
  }

  Future<bool> unsubscribe(String jid, String node) async {
    final attrs = getAttributes();
    final result = await attrs.sendStanza(
      Stanza.iq(
        type: 'set',
        to: jid,
        children: [
          XMLNode.xmlns(
            tag: 'pubsub',
            xmlns: pubsubXmlns,
            children: [
              XMLNode(
                tag: 'unsubscribe',
                attributes: <String, String>{
                  'node': node,
                  'jid': attrs.getFullJID().toBare().toString(),
                },
              ),
            ],
          ),
        ],
      ),
    );

    if (result.attributes['type'] != 'result') return false;

    final pubsub = result.firstTag('pubsub', xmlns: pubsubXmlns);
    if (pubsub == null) return false;

    final subscription = pubsub.firstTag('subscription');
    if (subscription == null) return false;

    return subscription.attributes['subscription'] == 'none';
  }

  /// Publish [payload] to the PubSub node [node] on JID [jid]. Returns true if it
  /// was successful. False otherwise.
  Future<bool> publish(String jid, String node, XMLNode payload, { String? id, PubSubPublishOptions? options }) async {
    // TODO(PapaTutuWawa): Clean this mess up
    if (options != null) {
      final dm = getAttributes().getManagerById<DiscoManager>(discoManager)!;
      final info = await dm.discoInfoQuery(jid);
      if (info == null) {
        if (options.maxItems == 'max') {
          logger.severe('disco#info query failed and options.maxItems is set to "max".');
          return false;
        }
      }

      final nodeMaxSupported = info != null && info.features.contains(pubsubNodeConfigMax);
      
      if (options.maxItems == 'max' && !nodeMaxSupported) {
        final items = await dm.discoItemsQuery(jid, node: node);
        var count = 1;
        if (items == null) {
          logger.severe('disco#items query failed and options.maxItems is set to "max". Assuming 0 items');
        } else {
          count = items.length + 1;
        }

        logger.finest('PubSub host does not support node-config-max. Working around it');
        options = PubSubPublishOptions(
          accessModel: options.accessModel,
          maxItems: '$count',
        );
      }
    }

    final result = await getAttributes().sendStanza(
      Stanza.iq(
        type: 'set',
        to: jid,
        children: [
          XMLNode.xmlns(
            tag: 'pubsub',
            xmlns: pubsubXmlns,
            children: [
              XMLNode(
                tag: 'publish',
                attributes: <String, String>{ 'node': node },
                children: [
                  XMLNode(
                    tag: 'item',
                    attributes: id != null ? <String, String>{ 'id': id } : <String, String>{},
                    children: [ payload ],
                  )
                ],
              ),
              ...options != null ? [
                XMLNode(
                  tag: 'publish-options',
                  children: [options.toXml()],
                ), 
              ] : [],
            ],
          )
        ],
      ),
    );

    if (result.attributes['type'] != 'result') return false;

    final pubsub = result.firstTag('pubsub', xmlns: pubsubXmlns);
    if (pubsub == null) return false;

    final publish = pubsub.firstTag('publish');
    if (publish == null) return false;

    final item = publish.firstTag('item');
    if (item == null) return false;

    if (id != null) return item.attributes['id'] == id;

    return true;
  }
  
  Future<List<PubSubItem>?> getItems(String jid, String node) async {
    final result = await getAttributes().sendStanza(
      Stanza.iq(
        type: 'get',
        to: jid,
        children: [
          XMLNode.xmlns(
            tag: 'pubsub',
            xmlns: pubsubXmlns,
            children: [
              XMLNode(tag: 'items', attributes: <String, String>{ 'node': node }),
            ],
          )
        ],
      ),
    );

    if (result.attributes['type'] != 'result') return null;

    final pubsub = result.firstTag('pubsub', xmlns: pubsubXmlns);
    if (pubsub == null) return null;

    return pubsub
      .firstTag('items')!
      .children.map((item) {
        return PubSubItem(
          id: item.attributes['id']! as String,
          payload: item.children[0],
          node: node,
        );
      })
      .toList();
  }

  Future<PubSubItem?> getItem(String jid, String node, String id) async {
    final result = await getAttributes().sendStanza(
      Stanza.iq(
        type: 'get',
        to: jid,
        children: [
          XMLNode.xmlns(
            tag: 'pubsub',
            xmlns: pubsubXmlns,
            children: [
              XMLNode(
                tag: 'items',
                attributes: <String, String>{ 'node': node },
                children: [
                  XMLNode(
                    tag: 'item',
                    attributes: <String, String>{ 'id': id },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    if (result.attributes['type'] != 'result') return null;

    final pubsub = result.firstTag('pubsub', xmlns: pubsubXmlns);
    if (pubsub == null) return null;

    final item = pubsub.firstTag('items')!.firstTag('item')!;
    return PubSubItem(
      id: item.attributes['id']! as String,
      payload: item.children[0],
      node: node,
    );
  }
}
