import "package:moxxyv2/xmpp/stanzas/stanza.dart";
import "package:moxxyv2/xmpp/connection.dart";
import "package:moxxyv2/repositories/xmpp.dart";

import "package:get_it/get_it.dart";

bool handleUnhandledStanza(XmppConnection conn, Stanza stanza) {
  conn.sendStanza(stanza.errorReply("cancel", "feature-not-implemented"));
  return true;
}
