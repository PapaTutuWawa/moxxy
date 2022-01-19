import "dart:collection";

import "package:moxxyv2/xmpp/events.dart";
import "package:moxxyv2/xmpp/namespaces.dart";
import "package:moxxyv2/xmpp/connection.dart";
import "package:moxxyv2/xmpp/stanzas/stanza.dart";
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
  REMOVE
}

class RosterItemNotFoundEvent extends XmppEvent {
  final String jid;
  final RosterItemNotFoundTrigger trigger;

  RosterItemNotFoundEvent({ required this.jid, required this.trigger });
}

// TODO: Add override-able functions commitRoster and commitRosterVersion
class RosterManager extends XmppManagerBase {
  @override
  String getId() => ROSTER_MANAGER;

  @override
  List<StanzaHandler> getStanzaHandlers() => [
    StanzaHandler(
      stanzaTag: "iq",
      tagName: "query",
      tagXmlns: ROSTER_XMLNS,
      callback: this._onRosterPush
    )
  ];

  bool _onRosterPush(Stanza stanza) {
    final attrs = this.getAttributes();

    attrs.log("Received roster push");

    if (stanza.attributes["from"] != null && stanza.attributes["from"] != attrs.getConnectionSettings().jid) {
      attrs.log("Roster push invalid! Unexpected from attribute");
      return true;
    }

    final query = stanza.firstTag("query", xmlns: ROSTER_XMLNS)!;
    final item = query.firstTag("item");

    if (item == null) {
      attrs.log("Error: Received empty roster push");
      // TODO: Error reply
      return true;
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
  Future<RosterRequestResult?> requestRoster(String? lastVersion) async {
    final attrs = getAttributes();
    final response = await attrs.sendStanza(
      Stanza.iq(
        type: "get",
        children: [
          XMLNode.xmlns(
            tag: "query",
            xmlns: ROSTER_XMLNS,
            attributes: {
              ...(lastVersion != null ? { "ver": lastVersion } : {})
            }
          )
        ]
      )
    );

    if (response.attributes["type"] != "result") {
      attrs.log("Error requesting roster: " + response.toString());
      return null;
    }

    final query = response.firstTag("query");

    final items;
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
      ver: query != null ? query.attributes["ver"] : lastVersion
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
            xmlns: ROSTER_XMLNS,
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

    if (response == null) {
      attrs.log("Error adding ${jid} to roster");
      return;
    }

    if (response.attributes["type"] != "result") {
      attrs.log("Error adding ${jid} to roster: " + response.toString());
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
            xmlns: ROSTER_XMLNS,
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
        attrs.sendEvent(RosterItemNotFoundEvent(jid: jid, trigger: RosterItemNotFoundTrigger.REMOVE));
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
