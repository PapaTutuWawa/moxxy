import 'package:moxxyv2/xmpp/events.dart';
import 'package:moxxyv2/xmpp/jid.dart';
import 'package:moxxyv2/xmpp/managers/base.dart';
import 'package:moxxyv2/xmpp/managers/data.dart';
import 'package:moxxyv2/xmpp/managers/handlers.dart';
import 'package:moxxyv2/xmpp/managers/namespaces.dart';
import 'package:moxxyv2/xmpp/namespaces.dart';
import 'package:moxxyv2/xmpp/stanza.dart';
import 'package:moxxyv2/xmpp/stringxml.dart';
import 'package:moxxyv2/xmpp/types/resultv2.dart';
import 'package:moxxyv2/xmpp/xeps/errors.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0004.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0030/errors.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0030/types.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0030/xep_0030.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0060/helpers.dart';

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

  Future<PubSubPublishOptions> _preprocessPublishOptions(String jid, String node, PubSubPublishOptions options) async {
    if (options.maxItems != null) {
      final dm = getAttributes().getManagerById<DiscoManager>(discoManager)!;
      final result = await dm.discoInfoQuery(jid);
      if (result.isType<DiscoError>()) {
        if (options.maxItems == 'max') {
          logger.severe('disco#info query failed and options.maxItems is set to "max".');
          return options;
        }
      }

      
      final nodeMaxSupported = result.isType<DiscoInfo>() && result.get<DiscoInfo>().features.contains(pubsubNodeConfigMax);
      if (options.maxItems == 'max' && !nodeMaxSupported) {
        final response = await dm.discoItemsQuery(jid, node: node);
        var count = 1;
        if (response.isType<DiscoError>()) {
          logger.severe('disco#items query failed and options.maxItems is set to "max". Assuming 0 items');
        } else {
          count = response.get<List<DiscoItem>>().length + 1;
        }

        logger.finest('PubSub host does not support node-config-max. Working around it');
        return PubSubPublishOptions(
          accessModel: options.accessModel,
          maxItems: '$count',
        );
      }
    }

    return options;
  }
  
  Future<Result<PubSubError, bool>> subscribe(String jid, String node) async {
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

    if (result.attributes['type'] != 'result') return Result(UnknownPubSubError());

    final pubsub = result.firstTag('pubsub', xmlns: pubsubXmlns);
    if (pubsub == null) return Result(UnknownPubSubError());

    final subscription = pubsub.firstTag('subscription');
    if (subscription == null) return Result(UnknownPubSubError());

    return Result(subscription.attributes['subscription'] == 'subscribed');
  }

  Future<Result<PubSubError, bool>> unsubscribe(String jid, String node) async {
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

    if (result.attributes['type'] != 'result') return Result(UnknownPubSubError());

    final pubsub = result.firstTag('pubsub', xmlns: pubsubXmlns);
    if (pubsub == null) return Result(UnknownPubSubError());

    final subscription = pubsub.firstTag('subscription');
    if (subscription == null) return Result(UnknownPubSubError());

    return Result(subscription.attributes['subscription'] == 'none');
  }

  Future<XMLNode> _publish(String jid, String node, XMLNode payload, { String? id, PubSubPublishOptions? options }) async {
    return getAttributes().sendStanza(
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
  }
  
  /// Publish [payload] to the PubSub node [node] on JID [jid]. Returns true if it
  /// was successful. False otherwise.
  Future<Result<PubSubError, bool>> publish(
    String jid,
    String node,
    XMLNode payload, {
      String? id,
      PubSubPublishOptions? options,
    }
  ) async {
    PubSubPublishOptions? pubOptions;
    if (options != null) {
      pubOptions = await _preprocessPublishOptions(jid, node, options);
    }

    var result = await _publish(jid, node, payload, id: id, options: pubOptions);
    if (result.attributes['type'] != 'result') {
      final error = getPubSubError(result);

      // If preconditions are not met, configure the node
      if (error is PreconditionsNotMetError) {
        final configureResult = await configure(jid, node, pubOptions!);
        if (configureResult.isType<PubSubError>()) {
          return Result(configureResult.get<PubSubError>());
        }

        result = await _publish(jid, node, payload, id: id, options: pubOptions);
        if (result.attributes['type'] != 'result') return Result(getPubSubError(result));
      }
    }

    final pubsub = result.firstTag('pubsub', xmlns: pubsubXmlns);
    if (pubsub == null) return Result(MalformedResponseError());

    final publish = pubsub.firstTag('publish');
    if (publish == null) return Result(MalformedResponseError());

    final item = publish.firstTag('item');
    if (item == null) return Result(MalformedResponseError());

    if (id != null) return Result(item.attributes['id'] == id);

    return const Result(true);
  }
  
  Future<Result<PubSubError, List<PubSubItem>>> getItems(String jid, String node) async {
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

    if (result.attributes['type'] != 'result') return Result(getPubSubError(result));

    final pubsub = result.firstTag('pubsub', xmlns: pubsubXmlns);
    if (pubsub == null) return Result(getPubSubError(result));

    final items = pubsub
      .firstTag('items')!
      .children.map((item) {
        return PubSubItem(
          id: item.attributes['id']! as String,
          payload: item.children[0],
          node: node,
        );
      })
      .toList();

    return Result(items);
  }

  Future<Result<PubSubError, PubSubItem>> getItem(String jid, String node, String id) async {
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

    if (result.attributes['type'] != 'result') return Result(getPubSubError(result));

    final pubsub = result.firstTag('pubsub', xmlns: pubsubXmlns);
    if (pubsub == null) return Result(getPubSubError(result));

    final itemElement = pubsub.firstTag('items')?.firstTag('item');
    if (itemElement == null) return Result(NoItemReturnedError());

    final item = PubSubItem(
      id: itemElement.attributes['id']! as String,
      payload: itemElement.children[0],
      node: node,
    );

    return Result(item);
  }

  Future<Result<PubSubError, bool>> configure(String jid, String node, PubSubPublishOptions options) async {
    final attrs = getAttributes();

    // Request the form
    final form = await attrs.sendStanza(
      Stanza.iq(
        type: 'get',
        to: jid,
        children: [
          XMLNode.xmlns(
            tag: 'pubsub',
            xmlns: pubsubOwnerXmlns,
            children: [
              XMLNode(
                tag: 'configure',
                attributes: <String, String>{
                  'node': node,
                },
              ),
            ],
          ),
        ],
      ),
    );
    if (form.attributes['type'] != 'result') return Result(getPubSubError(form));

    final submit = await attrs.sendStanza(
      Stanza.iq(
        type: 'set',
        to: jid,
        children: [
          XMLNode.xmlns(
            tag: 'pubsub',
            xmlns: pubsubOwnerXmlns,
            children: [
              XMLNode(
                tag: 'configure',
                attributes: <String, String>{
                  'node': node,
                },
                children: [
                  options.toXml(),
                ],
              ),
            ],
          ),
        ],
      ),
    );
    if (submit.attributes['type'] != 'result') return Result(getPubSubError(form));

    return const Result(true);
  }

  Future<Result<PubSubError, bool>> delete(JID host, String node, String itemId) async {
    final request = await getAttributes().sendStanza(
      Stanza.iq(
        type: 'set',
        to: host.toString(),
        children: [
          XMLNode.xmlns(
            tag: 'pubsub',
            xmlns: pubsubOwnerXmlns,
            children: [
              XMLNode(
                tag: 'delete',
                attributes: <String, String>{
                  'node': node,
                },
              ),
            ],
          ),
        ],
      ),
    ) as Stanza;

    if (request.type != 'result') {
      // TODO(Unknown): Be more specific
      return Result(UnknownPubSubError());
    }

    return const Result(true);
  }
}
