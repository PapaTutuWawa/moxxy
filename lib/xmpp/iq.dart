import "package:moxxyv2/xmpp/stanzas/stanza.dart";
import "package:moxxyv2/xmpp/connection.dart";
import "package:moxxyv2/repositories/xmpp.dart";

import "package:get_it/get_it.dart";

bool handleUnhandledStanza(XmppConnection conn, Stanza stanza) {
  conn.sendStanza(stanza.errorReply("cancel", "feature-not-implemented"));
  return true;
}

bool handleRosterPush(XmppConnection conn, Stanza stanza) {
  // Ignore
  if (stanza.attributes["from"] != conn.settings.jid) {
    return true;
  }

  // TODO: Handle the real roster push stuff and move it out of the repository
  final query = stanza.firstTag("query")!;
  GetIt.I.get<XmppRepository>().saveLastRosterVersion(query.attributes["ver"]!);
  
  return true;
}
