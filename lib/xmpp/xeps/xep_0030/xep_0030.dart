import 'dart:async';
import 'package:meta/meta.dart';
import 'package:moxxyv2/xmpp/events.dart';
import 'package:moxxyv2/xmpp/jid.dart';
import 'package:moxxyv2/xmpp/managers/base.dart';
import 'package:moxxyv2/xmpp/managers/data.dart';
import 'package:moxxyv2/xmpp/managers/handlers.dart';
import 'package:moxxyv2/xmpp/managers/namespaces.dart';
import 'package:moxxyv2/xmpp/namespaces.dart';
import 'package:moxxyv2/xmpp/presence.dart';
import 'package:moxxyv2/xmpp/stanza.dart';
import 'package:moxxyv2/xmpp/stringxml.dart';
import 'package:moxxyv2/xmpp/types/resultv2.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0004.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0030/errors.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0030/helpers.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0030/types.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0115.dart';
import 'package:synchronized/synchronized.dart';

@immutable
class DiscoCacheKey {

  const DiscoCacheKey(this.jid, this.node);
  final String jid;
  final String? node;

  @override
  bool operator ==(Object other) {
    return other is DiscoCacheKey && jid == other.jid && node == other.node;
  }
  
  @override
  int get hashCode => jid.hashCode ^ node.hashCode;
}

class DiscoManager extends XmppManagerBase {
 
  DiscoManager()
    : _features = List.empty(growable: true),
      _capHashCache = {},
      _capHashInfoCache = {},
      _discoInfoCache = {},
      _runningInfoQueries = {},
      _cacheLock = Lock(),
      super();
  /// Our features
  final List<String> _features;

  // Map full JID to Capability hashes
  final Map<String, CapabilityHashInfo> _capHashCache;
  // Map capability hash to the disco info
  final Map<String, DiscoInfo> _capHashInfoCache;
  // Map full JID to Disco Info
  final Map<DiscoCacheKey, DiscoInfo> _discoInfoCache;
  // Mapping the full JID to a list of running requests
  final Map<DiscoCacheKey, List<Completer<DiscoInfo?>>> _runningInfoQueries;
  // Cache lock
  final Lock _cacheLock;

  @visibleForTesting
  bool hasInfoQueriesRunning() => _runningInfoQueries.isNotEmpty;

  @visibleForTesting
  List<Completer<DiscoInfo?>> getRunningInfoQueries(DiscoCacheKey key) => _runningInfoQueries[key]!;
  
  @override
  List<StanzaHandler> getIncomingStanzaHandlers() => [
    StanzaHandler(
      tagName: 'query',
      tagXmlns: discoInfoXmlns,
      stanzaTag: 'iq',
      callback: _onDiscoInfoRequest,
    ),
    StanzaHandler(
      tagName: 'query',
      tagXmlns: discoItemsXmlns,
      stanzaTag: 'iq',
      callback: _onDiscoItemsRequest,
    ),
  ];

  @override
  String getId() => discoManager;

  @override
  String getName() => 'DiscoManager';

  @override
  List<String> getDiscoFeatures() => [ discoInfoXmlns, discoItemsXmlns ];

  @override
  Future<bool> isSupported() async => true;

  @override
  Future<void> onXmppEvent(XmppEvent event) async {
    if (event is PresenceReceivedEvent) {
      await _onPresence(event.jid, event.presence);
    } else if (event is StreamResumeFailedEvent) {
      await _cacheLock.synchronized(() async {
        // Clear the cache
        _discoInfoCache.clear();
      });
    }
  }
  
  /// Adds a list of features to the possible disco info response.
  /// This function only adds features that are not already present in the disco features.
  void addDiscoFeatures(List<String> features) {
    for (final feat in features) {
      if (!_features.contains(feat)) {
        _features.add(feat);
      }
    }
  }

  Future<void> _onPresence(JID from, Stanza presence) async {
    final c = presence.firstTag('c', xmlns: capsXmlns);
    if (c == null) return;

    final info = CapabilityHashInfo(
      c.attributes['ver']! as String,
      c.attributes['node']! as String,
      c.attributes['hash']! as String,
    );
    
    // Check if we already know of that cache
    var cached = false;
    await _cacheLock.synchronized(() async {
      if (!_capHashCache.containsKey(info.ver)) {
        cached = true;
      }
    });
    if (cached) return;

    // Request the cap hash
    logger.finest("Received capability hash we don't know about. Requesting it...");
    final result = await discoInfoQuery(from.toString(), node: '${info.node}#${info.ver}');
    if (result.isType<DiscoError>()) return;

    await _cacheLock.synchronized(() async {
      _capHashCache[from.toString()] = info;
      _capHashInfoCache[info.ver] = result.get<DiscoInfo>();
    });
  }
  
  /// Returns the list of disco features registered.
  List<String> getRegisteredDiscoFeatures() => _features;
  
  /// May be overriden. Specifies the identities which will be returned in a disco info response.
  List<Identity> getIdentities() => const [ Identity(category: 'client', type: 'pc', name: 'moxxmpp', lang: 'en') ];
  
  Future<StanzaHandlerData> _onDiscoInfoRequest(Stanza stanza, StanzaHandlerData state) async {
    if (stanza.type != 'get') return state;

    final presence = getAttributes().getManagerById(presenceManager)! as PresenceManager;
    final query = stanza.firstTag('query')!;
    final node = query.attributes['node'] as String?;
    final capHash = await presence.getCapabilityHash();
    final isCapabilityNode = node == 'http://moxxy.im#$capHash';

    if (!isCapabilityNode && node != null) {
      await getAttributes().sendStanza(Stanza.iq(
            to: stanza.from,
            from: stanza.to,
            id: stanza.id,
            type: 'error',
            children: [
              XMLNode.xmlns(
                tag: 'query',
                // TODO(PapaTutuWawa): Why are we copying the xmlns?
                xmlns: query.attributes['xmlns']! as String,
                attributes: <String, String>{
                  'node': node
                },
              ),
              XMLNode(
                tag: 'error',
                attributes: <String, String>{
                  'type': 'cancel'
                },
                children: [
                  XMLNode.xmlns(
                    tag: 'not-allowed',
                    xmlns: fullStanzaXmlns,
                  )
                ],
              )
            ],
          )
      ,);

      return state.copyWith(done: true);
    }

    await getAttributes().sendStanza(stanza.reply(
        children: [
          XMLNode.xmlns(
            tag: 'query',
            xmlns: discoInfoXmlns,
            attributes: {
              ...!isCapabilityNode ? {} : {
                  'node': 'http://moxxy.im#$capHash'
              }
            },
            children: [
              ...getIdentities().map((identity) => identity.toXMLNode()).toList(),
              ..._features.map((feat) {
                return XMLNode(
                  tag: 'feature',
                  attributes: <String, dynamic>{ 'var': feat },
                );
              }).toList(),
            ],
          ),
        ],
    ),);

    return state.copyWith(done: true);
  }

  Future<StanzaHandlerData> _onDiscoItemsRequest(Stanza stanza, StanzaHandlerData state) async {
    if (stanza.type != 'get') return state;

    final query = stanza.firstTag('query')!;
    if (query.attributes['node'] != null) {
      // TODO(Unknown): Handle the node we specified for XEP-0115
      await getAttributes().sendStanza(
        Stanza.iq(
          to: stanza.from,
          from: stanza.to,
          id: stanza.id,
          type: 'error',
          children: [
            XMLNode.xmlns(
              tag: 'query',
              // TODO(PapaTutuWawa): Why copy the xmlns?
              xmlns: query.attributes['xmlns']! as String,
              attributes: <String, String>{
                'node': query.attributes['node']! as String,
              },
            ),
            XMLNode(
              tag: 'error',
              attributes: <String, dynamic>{
                'type': 'cancel'
              },
              children: [
                XMLNode.xmlns(
                  tag: 'not-allowed',
                  xmlns: fullStanzaXmlns,
                ),
              ],
            ),
          ],
        ),
      );
      return state.copyWith(done: true);
    }

    await getAttributes().sendStanza(
      stanza.reply(
        children: [
          XMLNode.xmlns(
            tag: 'query',
            xmlns: discoItemsXmlns,
          ),
        ],
      ),
    );
    return state.copyWith(done: true);
  }

  Future<void> _exitDiscoInfoCriticalSection(DiscoCacheKey key, Result<DiscoError, DiscoInfo> result) async {
    return _cacheLock.synchronized(() async {
      final r = result.isType<DiscoInfo>() ? result.get<DiscoInfo>() : null;

      // Complete all futures
      for (final completer in _runningInfoQueries[key]!) {
        completer.complete(r);
      }

      // Add to cache if it is a result
      if (result.isType<DiscoInfo>()) {
        _discoInfoCache[key] = result.get<DiscoInfo>();
      }
      
      // Remove from the request cache
      _runningInfoQueries.remove(key);
    });
  }
  
  /// Sends a disco info query to the (full) jid [entity], optionally with node=[node].
  Future<Result<DiscoError, DiscoInfo>> discoInfoQuery(String entity, { String? node}) async {
    final cacheKey = DiscoCacheKey(entity, node);
    DiscoInfo? info;
    Completer<DiscoInfo?>? completer;
    await _cacheLock.synchronized(() async {
      // Check if we already know what the JID supports
      if (_discoInfoCache.containsKey(cacheKey)) {
        info = _discoInfoCache[cacheKey];
      } else {
        // Is a request running?
        if (_runningInfoQueries.containsKey(cacheKey)) {
          completer = Completer();
          _runningInfoQueries[cacheKey]!.add(completer!);
        } else {
          _runningInfoQueries[cacheKey] = List.from(<Completer<DiscoInfo?>>[]);
        }
      }
    });

    if (info != null) {
      final result = Result<DiscoError, DiscoInfo>(info);
      await _exitDiscoInfoCriticalSection(cacheKey, result);
      return result;
    } else if (completer != null) {
      final result = Result<DiscoError, DiscoInfo>(await completer!.future);
      await _exitDiscoInfoCriticalSection(cacheKey, result);
      return result;
    }

    final stanza = await getAttributes().sendStanza(
      buildDiscoInfoQueryStanza(entity, node),
    );
    final query = stanza.firstTag('query');
    if (query == null) {
      final result = Result<DiscoError, DiscoInfo>(InvalidResponseDiscoError());
      await _exitDiscoInfoCriticalSection(cacheKey, result);
      return result;
    }

    final error = stanza.firstTag('error');
    if (error != null && stanza.attributes['type'] == 'error') {
      final result = Result<DiscoError, DiscoInfo>(ErrorResponseDiscoError());
      await _exitDiscoInfoCriticalSection(cacheKey, result);
      return result;
    }
    
    final features = List<String>.empty(growable: true);
    final identities = List<Identity>.empty(growable: true);

    for (final element in query.children) {
      if (element.tag == 'feature') {
        features.add(element.attributes['var']! as String);
      } else if (element.tag == 'identity') {
        identities.add(Identity(
          category: element.attributes['category']! as String,
          type: element.attributes['type']! as String,
          name: element.attributes['name'] as String?,
        ),);
      }
    }

    final result = Result<DiscoError, DiscoInfo>(
      DiscoInfo(
        features,
        identities,
        query.findTags('x', xmlns: dataFormsXmlns).map(parseDataForm).toList(),
        JID.fromString(stanza.attributes['from']! as String),
      ),
    );
    await _exitDiscoInfoCriticalSection(cacheKey, result);
    return result;
  }

  /// Sends a disco items query to the (full) jid [entity], optionally with node=[node].
  Future<Result<DiscoError, List<DiscoItem>>> discoItemsQuery(String entity, { String? node }) async {
    final stanza = await getAttributes()
      .sendStanza(buildDiscoItemsQueryStanza(entity, node: node)) as Stanza;

    final query = stanza.firstTag('query');
    if (query == null) return Result(InvalidResponseDiscoError());

    final error = stanza.firstTag('error');
    if (error != null && stanza.type == 'error') {
      //print("Disco Items error: " + error.toXml());
      return Result(ErrorResponseDiscoError());
    }

    final items = query.findTags('item').map((node) => DiscoItem(
      jid: node.attributes['jid']! as String,
      node: node.attributes['node'] as String?,
      name: node.attributes['name'] as String?,
    ),).toList();

    return Result(items);
  }

  /// Queries information about a jid based on its node and capability hash.
  Future<Result<DiscoError, DiscoInfo>> discoInfoCapHashQuery(String jid, String node, String ver) async {
    return discoInfoQuery(jid, node: '$node#$ver');
  }

  Future<Result<DiscoError, List<DiscoInfo>>> performDiscoSweep() async {
    final attrs = getAttributes();
    final serverJid = attrs.getConnectionSettings().jid.domain;
    final infoResults = List<DiscoInfo>.empty(growable: true);
    final result = await discoInfoQuery(serverJid);
    if (result.isType<DiscoInfo>()) {
      final info = result.get<DiscoInfo>();
      logger.finest('Discovered supported server features: ${info.features}');
      infoResults.add(info);

      attrs.sendEvent(ServerItemDiscoEvent(info));
      attrs.sendEvent(ServerDiscoDoneEvent());
    } else {
      logger.warning('Failed to discover server features');
      return Result(UnknownDiscoError());
    }

    final response = await discoItemsQuery(serverJid);
    if (response.isType<List<DiscoItem>>()) {
      logger.finest('Discovered disco items form $serverJid');

      // Query all items
      final items = response.get<List<DiscoItem>>();
      for (final item in items) {
        logger.finest('Querying info for ${item.jid}...');
        final itemInfoResult = await discoInfoQuery(item.jid);
        if (itemInfoResult.isType<DiscoInfo>()) {
          final itemInfo = itemInfoResult.get<DiscoInfo>();
          logger.finest('Received info for ${item.jid}');
          infoResults.add(itemInfo);
          attrs.sendEvent(ServerItemDiscoEvent(itemInfo));
        } else {
          logger.warning('Failed to discover info for ${item.jid}');
        }
      }
    } else {
      logger.warning('Failed to discover items of $serverJid');
    }

    return Result(infoResults);
  }

  /// A wrapper function around discoInfoQuery: Returns true if the entity with JID
  /// [entity] supports the disco feature [feature]. If not, returns false.
  Future<bool> supportsFeature(JID entity, String feature) async {
    final info = await discoInfoQuery(entity.toString());
    if (info.isType<DiscoError>()) return false;

    return info.get<DiscoInfo>().features.contains(feature);
  }
}
