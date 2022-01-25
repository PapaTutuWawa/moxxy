import "package:moxxyv2/xmpp/managers/attributes.dart";
import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/events.dart";
import "package:moxxyv2/xmpp/stanza.dart";
import "package:moxxyv2/xmpp/settings.dart";
import "package:moxxyv2/xmpp/jid.dart";
import "package:moxxyv2/xmpp/xeps/xep_0198.dart";

import "../helpers/xml.dart";

import "package:test/test.dart";

void main() {
  final stanza = Stanza(
    to: "some.user@server.example",
    tag: "message"
  );

  test("Test Stream Management", () async {
      Stanza lastSentStanza = Stanza(tag: "message");

      final attributes = XmppManagerAttributes(
        // ignore: avoid_print
        log: (msg) => print(msg),
        sendStanza: (stanza, { bool addFrom = true, bool addId = true }) async {
          // ignore: avoid_print
          print("==> " + stanza.toXml());
          lastSentStanza = stanza;
          return XMLNode(tag: "hallo");
        },
        sendNonza: (nonza) {},
        sendEvent: (event) {},
        sendRawXml: (raw) {},
        getManagerById: (id) => null,
        getConnectionSettings: () => ConnectionSettings(
          jid: BareJID.fromString("hallo@example.server"),
          password: "password",
          useDirectTLS: true,
          allowPlainAuth: false,
        ),
        isStreamFeatureSupported: (feat) => false,
        getFullJID: () => FullJID.fromString("hallo@example.server/uwu")
      );
      final manager = StreamManagementManager();
      manager.register(attributes);
      manager.onXmppEvent(StreamManagementEnabledEvent(id: "0", resource: "h"));
      
      // Receive a fake stanza
      await manager.runStanzaHandlers(stanza);
      await manager.runStanzaHandlers(stanza);
      expect(manager.getS2CStanzaCount(), 2, reason: "The S2C counter must count correctly");

      // Send some fake stanzas
      manager.onXmppEvent(StanzaSentEvent(stanza: stanza));
      manager.onXmppEvent(StanzaSentEvent(stanza: stanza));
      manager.onXmppEvent(StanzaSentEvent(stanza: stanza));
      expect(manager.getC2SStanzaCount(), 3, reason: "The C2S counter must count correctly");

      final ack = XMLNode.xmlns(tag: "a", xmlns: "urn:xmpp:sm:3", attributes: { "h": "3" });
      await manager.runNonzaHandlers(ack);
      expect(manager.getUnackedStanzas().isEmpty, true, reason: "All C2S stanzas have been acknoledged. The queue should be empty.");
      expect(manager.getS2CStanzaCount(), 2, reason: "Sending stanzas must not change the S2C counter");

      // Send a stanza which we will not acknowledge
      manager.onXmppEvent(StanzaSentEvent(stanza: stanza));
      expect(manager.getC2SStanzaCount(), 4, reason: "Sending a stanza must increment the C2S counter");
      await manager.runNonzaHandlers(ack);
      // NOTE: In production this should be 4 since we have a Stream broadcasting an
      //       StanzaSent event. We don't here.
      expect(manager.getC2SStanzaCount(), 3, reason: "Retransmitting a stanza must not change the counter");
      expect(compareXMLNodes(lastSentStanza, stanza), true, reason: "Unacknowledged C2S stanzas must be retransmitted");
  });

  test("Test stream resumption", () async {
      Stanza lastSentStanza = Stanza(tag: "message");

      final attributes = XmppManagerAttributes(
        // ignore: avoid_print
        log: (msg) => print(msg),
        sendStanza: (stanza, { bool addFrom = true, bool addId = true }) async {
          // ignore: avoid_print
          print("==> " + stanza.toXml());
          lastSentStanza = stanza;
          return XMLNode(tag: "hallo");
        },
        sendNonza: (nonza) {},
        sendEvent: (event) {},
        sendRawXml: (raw) {},
        getManagerById: (id) => null,
        getConnectionSettings: () => ConnectionSettings(
          jid: BareJID.fromString("hallo@example.server"),
          password: "password",
          useDirectTLS: true,
          allowPlainAuth: false,
        ),
        isStreamFeatureSupported: (feat) => false,
        getFullJID: () => FullJID.fromString("hallo@example.server/uwu")
      );
      final manager = StreamManagementManager();
      manager.register(attributes);

      // Send some stanzas
      manager.onXmppEvent(StanzaSentEvent(stanza: stanza));
      manager.onXmppEvent(StanzaSentEvent(stanza: stanza));
      manager.onXmppEvent(StanzaSentEvent(stanza: stanza));

      // Simulate a resumption
      manager.onXmppEvent(StreamResumedEvent(h: 2));
      expect(compareXMLNodes(lastSentStanza, stanza), true, reason: "Unacked stanzas should be retransmitted on stream resumption");
  });
}
