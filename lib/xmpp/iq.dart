import "package:moxxyv2/xmpp/stanza.dart";
import "package:moxxyv2/xmpp/connection.dart";

bool handleUnhandledStanza(XmppConnection conn, Stanza stanza) {
  if (stanza.type != "error") {
    conn.sendStanza(stanza.errorReply("cancel", "feature-not-implemented"));
  }

  return true;
}
