import "package:moxxyv2/xmpp/stanzas/stanza.dart";
import "package:moxxyv2/xmpp/connection.dart";
import "package:moxxyv2/xmpp/events.dart";

bool handleMessageStanza(XmppConnection conn, Stanza stanza) {
  final body = stanza.firstTag("body");
  if (body == null) return true;
  
  conn.sendEvent(MessageEvent(
      body: body.innerText(),
      fromJid: stanza.attributes["from"]!,
      sid: stanza.attributes["id"]!
  ));

  return true;
}
