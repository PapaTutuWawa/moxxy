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
}
