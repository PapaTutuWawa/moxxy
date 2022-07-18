import 'package:moxxyv2/xmpp/events.dart';
import 'package:moxxyv2/xmpp/jid.dart';
import 'package:moxxyv2/xmpp/managers/base.dart';
import 'package:moxxyv2/xmpp/managers/data.dart';
import 'package:moxxyv2/xmpp/managers/handlers.dart';
import 'package:moxxyv2/xmpp/managers/namespaces.dart';
import 'package:moxxyv2/xmpp/namespaces.dart';
import 'package:moxxyv2/xmpp/negotiators/namespaces.dart';
import 'package:moxxyv2/xmpp/negotiators/negotiator.dart';
import 'package:moxxyv2/xmpp/stanza.dart';
import 'package:moxxyv2/xmpp/stringxml.dart';
import 'package:moxxyv2/xmpp/types/error.dart';

const rosterErrorNoQuery = 1;
const rosterErrorNonResult = 2;

class XmppRosterItem {

  XmppRosterItem({ required this.jid, required this.subscription, this.ask, this.name, this.groups = const [] });
  final String jid;
  final String? name;
  final String subscription;
  final String? ask;
  final List<String> groups;
}

enum RosterRemovalResult {
  okay,
  error,
  itemNotFound
}

class RosterRequestResult {

  RosterRequestResult({ required this.items, this.ver });
  List<XmppRosterItem> items;
  String? ver;
}

class RosterPushEvent extends XmppEvent {

  RosterPushEvent({ required this.item, this.ver });
  final XmppRosterItem item;
  final String? ver;
}

/// A Stub feature negotiator for finding out whether roster versioning is supported.
class RosterFeatureNegotiator extends XmppFeatureNegotiatorBase {
  RosterFeatureNegotiator() : _supported = false, super(0, false, rosterNegotiator, rosterVersioningXmlns);

  /// True if rosterVersioning is supported. False otherwise.
  bool _supported;
  bool get isSupported => _supported;
  
  @override
  Future<void> negotiate(XMLNode nonza) async {
    // negotiate is only called when the negotiator matched, meaning the server
    // advertises roster versioning.
    _supported = true;
    state = NegotiatorState.done;
  }

  @override
  void reset() {
    _supported = false;

    super.reset();
  }
}

/// This manager requires a RosterFeatureNegotiator to be registered.
class RosterManager extends XmppManagerBase {

  RosterManager() : _rosterVersion = null, super();
  String? _rosterVersion;
  
  @override
  String getId() => rosterManager;

  @override
  String getName() => 'RosterManager';

  @override
  List<StanzaHandler> getIncomingStanzaHandlers() => [
    StanzaHandler(
      stanzaTag: 'iq',
      tagName: 'query',
      tagXmlns: rosterXmlns,
      callback: _onRosterPush,
    )
  ];

  /// Override-able functions
  Future<void> commitLastRosterVersion(String version) async {}
  Future<void> loadLastRosterVersion() async {}

  void setRosterVersion(String ver) {
    assert(_rosterVersion == null, 'A roster version must not be empty');

    _rosterVersion = ver;
  }
 
  Future<StanzaHandlerData> _onRosterPush(Stanza stanza, StanzaHandlerData state) async {
    final attrs = getAttributes();
    final from = stanza.attributes['from'] as String?;
    final selfJid = attrs.getConnectionSettings().jid;

    logger.fine('Received roster push');

    // Only allow the push if the from attribute is either
    // - empty, i.e. not set
    // - a full JID of our own
    if (from != null && JID.fromString(from).toBare() != selfJid) {
      logger.warning('Roster push invalid! Unexpected from attribute: ${stanza.toXml()}');
      return state.copyWith(done: true);
    }

    final query = stanza.firstTag('query', xmlns: rosterXmlns)!;
    final item = query.firstTag('item');

    if (item == null) {
      logger.warning('Received empty roster push');
      return state.copyWith(done: true);
    }

    if (query.attributes['ver'] != null) {
      final ver = query.attributes['ver']! as String;
      await commitLastRosterVersion(ver);
      _rosterVersion = ver;
    }
    
    attrs.sendEvent(RosterPushEvent(
      item: XmppRosterItem(
        jid: item.attributes['jid']! as String,
        subscription: item.attributes['subscription']! as String,
        ask: item.attributes['ask'] as String?,
        name: item.attributes['name'] as String?, 
      ),
      ver: query.attributes['ver'] as String?,
    ),);
    await attrs.sendStanza(stanza.reply());

    return state.copyWith(done: true);
  }

  /// Shared code between requesting rosters without and with roster versioning, if
  /// the server deems a regular roster response more efficient than n roster pushes.
  Future<MayFail<RosterRequestResult>> _handleRosterResponse(XMLNode? query) async {
    final List<XmppRosterItem> items;
    if (query != null) {
      items = query.children.map((item) => XmppRosterItem(
        name: item.attributes['name'] as String?,
        jid: item.attributes['jid']! as String,
        subscription: item.attributes['subscription']! as String,
        ask: item.attributes['ask'] as String,
        groups: item.findTags('group').map((groupNode) => groupNode.innerText()).toList(),
      ),).toList();

      if (query.attributes['ver'] != null) {
        final ver_ = query.attributes['ver']! as String;
        await commitLastRosterVersion(ver_);
        _rosterVersion = ver_;
      }
    } else {
      logger.warning('Server response to roster request without roster versioning does not contain a <query /> element, while the type is not error. This violates RFC6121');
      return MayFail.failure(rosterErrorNoQuery);
    }

    final ver = query.attributes['ver'] as String?;
    if (ver != null) {
      _rosterVersion = ver;
      await commitLastRosterVersion(ver);
    }
    
    return MayFail.success(
      RosterRequestResult(
        items: items,
        ver: ver,
      ),
    );

  }
  
  /// Requests the roster following RFC 6121 without using roster versioning.
  Future<MayFail<RosterRequestResult>> requestRoster() async {
    final attrs = getAttributes();
    final response = await attrs.sendStanza(
      Stanza.iq(
        type: 'get',
        children: [
          XMLNode.xmlns(
            tag: 'query',
            xmlns: rosterXmlns,
          )
        ],
      ),
    );

    if (response.attributes['type'] != 'result') {
      logger.warning('Error requesting roster without roster versioning: ${response.toXml()}');
      return MayFail.failure(rosterErrorNonResult);
    }

    final query = response.firstTag('query', xmlns: rosterXmlns);
    return _handleRosterResponse(query);
  }

  /// Requests a series of roster pushes according to RFC6121. Requires that the server
  /// advertises urn:xmpp:features:rosterver in the stream features.
  Future<MayFail<RosterRequestResult?>> requestRosterPushes() async {
    if (_rosterVersion == null) {
      await loadLastRosterVersion();
    }

    final attrs = getAttributes();
    final result = await attrs.sendStanza(
      Stanza.iq(
        type: 'get',
        children: [
          XMLNode.xmlns(
            tag: 'query',
            xmlns: rosterXmlns,
            attributes: {
              'ver': _rosterVersion ?? ''
            },
          )
        ],
      ),
    );

    if (result.attributes['type'] != 'result') {
      logger.warning('Requesting roster pushes failed: ${result.toXml()}');
      return MayFail.failure(rosterErrorNonResult);
    }

    final query = result.firstTag('query', xmlns: rosterXmlns);
    return _handleRosterResponse(query);
  }

  bool rosterVersioningAvailable() {
    return getAttributes().getNegotiatorById<RosterFeatureNegotiator>(rosterNegotiator)!.isSupported;
  }
  
  /// Attempts to add [jid] with a title of [title] and groups [groups] to the roster.
  /// Returns true if the process was successful, false otherwise.
  Future<bool> addToRoster(String jid, String title, { List<String>? groups }) async {
    final attrs = getAttributes();
    final response = await attrs.sendStanza(
      Stanza.iq(
        type: 'set',
        children: [
          XMLNode.xmlns(
            tag: 'query',
            xmlns: rosterXmlns,
            children: [
              XMLNode(
                tag: 'item',
                attributes: <String, String>{
                  'jid': jid,
                  ...title == jid.split('@')[0] ? <String, String>{} : <String, String>{ 'name': title }
                },
                children: (groups ?? []).map((group) => XMLNode(tag: 'group', text: group)).toList(),
              )
            ],
          )
        ],
      ),
    );

    if (response.attributes['type'] != 'result') {
      logger.severe('Error adding $jid to roster: $response');
      return false;
    }

    return true;
  }

  /// Attempts to remove [jid] from the roster. Returns true if the process was successful,
  /// false otherwise.
  Future<RosterRemovalResult> removeFromRoster(String jid) async {
    final attrs = getAttributes();
    final response = await attrs.sendStanza(
      Stanza.iq(
        type: 'set',
        children: [
          XMLNode.xmlns(
            tag: 'query',
            xmlns: rosterXmlns,
            children: [
              XMLNode(
                tag: 'item',
                attributes: <String, String>{
                  'jid': jid,
                  'subscription': 'remove'
                },
              )
            ],
          )
        ],
      ),
    );

    if (response.attributes['type'] != 'result') {
      logger.severe('Failed to remove roster item: ${response.toXml()}');

      final error = response.firstTag('error')!;
      final notFound = error.firstTag('item-not-found') != null;

      if (notFound) {
        logger.warning('Item was not found');
        return RosterRemovalResult.itemNotFound;
      }

      return RosterRemovalResult.error;
    }

    return RosterRemovalResult.okay;
  }
}
