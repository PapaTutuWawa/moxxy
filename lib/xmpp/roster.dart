import "package:moxxyv2/xmpp/events.dart";
import "package:moxxyv2/xmpp/namespaces.dart";
import "package:moxxyv2/xmpp/stanza.dart";
import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/jid.dart";
import "package:moxxyv2/xmpp/managers/base.dart";
import "package:moxxyv2/xmpp/managers/namespaces.dart";
import "package:moxxyv2/xmpp/managers/data.dart";
import "package:moxxyv2/xmpp/managers/handlers.dart";

class XmppRosterItem {
  final String jid;
  final String? name;
  final String subscription;
  final List<String> groups;

  XmppRosterItem({ required this.jid, required this.subscription, this.name, this.groups = const [] });
}

enum RosterRemovalResult {
  okay,
  error,
  itemNotFound
}

class RosterRequestResult {
  List<XmppRosterItem> items;
  String? ver;

  RosterRequestResult({ required this.items, this.ver });
}

class RosterPushEvent extends XmppEvent {
  final XmppRosterItem item;
  final String? ver;

  RosterPushEvent({ required this.item, this.ver });
}

class RosterManager extends XmppManagerBase {
  String? _rosterVersion;

  RosterManager() : _rosterVersion = null, super();
  
  @override
  String getId() => rosterManager;

  @override
  String getName() => "RosterManager";

  @override
  List<StanzaHandler> getIncomingStanzaHandlers() => [
    StanzaHandler(
      stanzaTag: "iq",
      tagName: "query",
      tagXmlns: rosterXmlns,
      callback: _onRosterPush
    )
  ];

  /// Override-able functions
  Future<void> commitLastRosterVersion(String version) async {}
  Future<void> loadLastRosterVersion() async {}

  void setRosterVersion(String ver) {
    assert(_rosterVersion == null);

    _rosterVersion = ver;
  }
 
  Future<StanzaHandlerData> _onRosterPush(Stanza stanza, StanzaHandlerData state) async {
    final attrs = getAttributes();
    final from = stanza.attributes["from"];
    final selfJid = attrs.getConnectionSettings().jid;

    logger.fine("Received roster push");

    // Only allow the push if the from attribute is either
    // - empty, i.e. not set
    // - a full JID of our own
    if (from != null && JID.fromString(stanza.attributes["from"]).toBare() != selfJid) {
      logger.warning("Roster push invalid! Unexpected from attribute: ${stanza.toXml()}");
      return state.copyWith(done: true);
    }

    final query = stanza.firstTag("query", xmlns: rosterXmlns)!;
    final item = query.firstTag("item");

    if (item == null) {
      logger.warning("Received empty roster push");
      return state.copyWith(done: true);
    }

    if (query.attributes["ver"] != null) {
      commitLastRosterVersion(query.attributes["ver"]);
      _rosterVersion = query.attributes["ver"];
    }
    
    attrs.sendEvent(RosterPushEvent(
        item: XmppRosterItem(
          jid: item.attributes["jid"]!,
          subscription: item.attributes["subscription"]!,
          name: item.attributes["name"], 
        ),
        ver: query.attributes["ver"]
    ));
    attrs.sendStanza(stanza.reply());

    return state.copyWith(done: true);
  }

  /// Requests the roster from the server. [lastVersion] refers to the last version
  /// of the roster we know about according to roster versioning.
  Future<RosterRequestResult?> requestRoster() async {
    if (_rosterVersion == null) {
      await loadLastRosterVersion();
    }

    final attrs = getAttributes();
    final response = await attrs.sendStanza(
      Stanza.iq(
        type: "get",
        children: [
          XMLNode.xmlns(
            tag: "query",
            xmlns: rosterXmlns,
            attributes: {
              ...(_rosterVersion != null ? { "ver": _rosterVersion! } : {})
            }
          )
        ]
      )
    );

    if (response.attributes["type"] != "result") {
      logger.severe("Error requesting roster: " + response.toString());
      return null;
    }

    final XMLNode? query = response.firstTag("query");

    final List<XmppRosterItem> items;
    if (query != null) {
      items = query.children.map((item) => XmppRosterItem(
          name: item.attributes["name"],
          jid: item.attributes["jid"]!,
          subscription: item.attributes["subscription"]!,
          groups: item.findTags("group").map((groupNode) => groupNode.innerText()).toList()
      )).toList();

      if (query.attributes["ver"] != null) {
        commitLastRosterVersion(query.attributes["ver"]);
        _rosterVersion = query.attributes["ver"];
      }
    } else {
      items = List<XmppRosterItem>.empty();
    }
    
    return RosterRequestResult(
      items: items,
      ver: query != null ? query.attributes["ver"] : _rosterVersion
    );
  }

  /// Attempts to add [jid] with a title of [title] and groups [groups] to the roster.
  /// Returns true if the process was successful, false otherwise.
  Future<bool> addToRoster(String jid, String title, { List<String>? groups }) async {
    final attrs = getAttributes();
    final response = await attrs.sendStanza(
      Stanza.iq(
        type: "set",
        children: [
          XMLNode.xmlns(
            tag: "query",
            xmlns: rosterXmlns,
            children: [
              XMLNode(
                tag: "item",
                attributes: {
                  "jid": jid,
                  ...(title == jid.split("@")[0] ? {} : { "name": title })
                },
                children: (groups ?? []).map((group) => XMLNode(tag: "group", text: group)).toList()
              )
            ]
          )
        ]
      )
    );

    if (response.attributes["type"] != "result") {
      logger.severe("Error adding $jid to roster: " + response.toString());
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
        type: "set",
        children: [
          XMLNode.xmlns(
            tag: "query",
            xmlns: rosterXmlns,
            children: [
              XMLNode(
                tag: "item",
                attributes: {
                  "jid": jid,
                  "subscription": "remove"
                }
              )
            ]
          )
        ]
      )
    );

    if (response.attributes["type"] != "result") {
      logger.severe("Failed to remove roster item: " + response.toXml());

      final error = response.firstTag("error")!;
      final notFound = error.firstTag("item-not-found") != null;

      if (notFound) {
        logger.warning("Item was not found");
        return RosterRemovalResult.itemNotFound;
      }

      return RosterRemovalResult.error;
    }

    return RosterRemovalResult.okay;
  }
}
