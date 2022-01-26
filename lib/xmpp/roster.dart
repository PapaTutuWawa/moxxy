import "package:moxxyv2/xmpp/events.dart";
import "package:moxxyv2/xmpp/namespaces.dart";
import "package:moxxyv2/xmpp/stanza.dart";
import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/managers/base.dart";
import "package:moxxyv2/xmpp/managers/namespaces.dart";
import "package:moxxyv2/xmpp/managers/handlers.dart";

class XmppRosterItem {
  final String jid;
  final String? name;
  final String subscription;
  final List<String> groups;

  XmppRosterItem({ required this.jid, required this.subscription, this.name, this.groups = const [] });
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

enum RosterItemNotFoundTrigger {
  remove
}

class RosterItemNotFoundEvent extends XmppEvent {
  final String jid;
  final RosterItemNotFoundTrigger trigger;

  RosterItemNotFoundEvent({ required this.jid, required this.trigger });
}

class RosterManager extends XmppManagerBase {
  String? _rosterVersion;

  RosterManager() : _rosterVersion = null, super();
  
  @override
  String getId() => rosterManager;

  @override
  List<StanzaHandler> getStanzaHandlers() => [
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
 
  Future<bool> _onRosterPush(Stanza stanza) async {
    final attrs = getAttributes();

    attrs.log("Received roster push");

    if (stanza.attributes["from"] != null || stanza.attributes["from"] != attrs.getConnectionSettings().jid) {
      attrs.log("Roster push invalid! Unexpected from attribute");
      return true;
    }

    final query = stanza.firstTag("query", xmlns: rosterXmlns)!;
    final item = query.firstTag("item");

    if (item == null) {
      attrs.log("Error: Received empty roster push");
      // TODO: Error reply
      return true;
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

    return true;
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
      attrs.log("Error requesting roster: " + response.toString());
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
    } else {
      items = List<XmppRosterItem>.empty();
    }

    return RosterRequestResult(
      items: items,
      ver: query != null ? query.attributes["ver"] : _rosterVersion
    );
  }

  // TODO: The type makes no sense (how?)
  /// Attempts to add [jid] with a title of [title] to the roster.
  Future<void> addToRoster(String jid, String title) async {
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
              })
            ]
          )
        ]
      )
    );

    if (response.attributes["type"] != "result") {
      attrs.log("Error adding $jid to roster: " + response.toString());
      return;
    }
  }

  /// Attempts to remove [jid] from the roster.
  Future<void> removeFromRoster(String jid) async {
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
      attrs.log("Failed to remove roster item: " + response.toXml());

      final error = response.firstTag("error")!;
      final notFound = error.firstTag("item-not-found") != null;

      if (notFound) {
        attrs.sendEvent(RosterItemNotFoundEvent(jid: jid, trigger: RosterItemNotFoundTrigger.remove));
      }
    }
  }

  /// Sends a subscription request to [to].
  Future<void> sendSubscriptionRequest(String to) async {
    await getAttributes().sendStanza(
      Stanza.presence(
        type: "subscribe",
        to: to
      )
    );
  }

  /// Sends an unsubscription request to [to].
  Future<void> sendUnsubscriptionRequest(String to) async {
    await getAttributes().sendStanza(
      Stanza.presence(
        type: "unsubscribe",
        to: to
      )
    );
  }
}
