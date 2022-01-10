import "dart:collection";

import "package:moxxyv2/xmpp/events.dart";
import "package:moxxyv2/xmpp/namespaces.dart";
import "package:moxxyv2/xmpp/connection.dart";
import "package:moxxyv2/xmpp/stanzas/stanza.dart";
import "package:moxxyv2/xmpp/stringxml.dart";

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

bool handleRosterPush(XmppConnection conn, Stanza stanza) {
  // Ignore
  print("Received roster push");

  if (stanza.attributes["from"] != null && stanza.attributes["from"] != conn.settings.jid) {
    print("Roster push invalid!");
    return true;
  }
  
  // NOTE: StanzaHandler gurantees that this is != null
  final query = stanza.firstTag("query", xmlns: ROSTER_XMLNS)!;
  final item = query.firstTag("item");

  if (item == null) {
    print("Error: Received empty roster push: " + stanza.toXml());
    // TODO: Error reply
    return true;
  }

  conn.sendEvent(RosterPushEvent(
      item: XmppRosterItem(
        jid: item.attributes["jid"]!,
        subscription: item.attributes["subscription"]!,
        name: item.attributes["name"], 
      ),
      ver: query.attributes["ver"]
  ));
  conn.sendStanza(stanza.reply());
  
  return true;
}
