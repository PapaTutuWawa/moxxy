import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/events.dart";
import "package:moxxyv2/xmpp/stanza.dart";
import "package:moxxyv2/xmpp/settings.dart";
import "package:moxxyv2/xmpp/jid.dart";
import "package:moxxyv2/xmpp/connection.dart";
import "package:moxxyv2/xmpp/managers/attributes.dart";
import "package:moxxyv2/xmpp/managers/data.dart";
import "package:moxxyv2/xmpp/xeps/xep_0198/xep_0198.dart";
import "package:moxxyv2/xmpp/xeps/xep_0198/state.dart";

import "../helpers/xml.dart";

import "package:test/test.dart";

Future<void> runIncomingStanzaHandlers(StreamManagementManager man, Stanza stanza) async {
  for (final handler in man.getIncomingStanzaHandlers()) {
    if (handler.matches(stanza)) await handler.callback(stanza, StanzaHandlerData(false, stanza));
  }
}

Future<void> runOutgoingStanzaHandlers(StreamManagementManager man, Stanza stanza) async {
  for (final handler in man.getOutgoingStanzaHandlers()) {
    if (handler.matches(stanza)) await handler.callback(stanza, StanzaHandlerData(false, stanza));
  }
}

void main() {
  final stanza = Stanza(
    to: "some.user@server.example",
    tag: "message"
  );

  test("Test Stream Management", () async {
      Stanza lastSentStanza = Stanza(tag: "message");

      final attributes = XmppManagerAttributes(
        sendStanza: (stanza, { StanzaFromType addFrom = StanzaFromType.full, bool addId = true, bool retransmitted = false, bool awaitable = true }) async {
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
          jid: JID.fromString("hallo@example.server"),
          password: "password",
          useDirectTLS: true,
          allowPlainAuth: false,
        ),
        isStreamFeatureSupported: (feat) => false,
        isFeatureSupported: (_) => false,
        getFullJID: () => JID.fromString("hallo@example.server/uwu")
      );
      final manager = StreamManagementManager();
      manager.register(attributes);
      manager.onXmppEvent(StreamManagementEnabledEvent(id: "0", resource: "h"));
      
      // Receive a fake stanza
      await runIncomingStanzaHandlers(manager, stanza);
      await runIncomingStanzaHandlers(manager, stanza);
      expect(manager.state.s2c, 2, reason: "The S2C counter must count correctly");

      // Send some fake stanzas
      runOutgoingStanzaHandlers(manager, stanza);
      runOutgoingStanzaHandlers(manager, stanza);
      runOutgoingStanzaHandlers(manager, stanza);
      expect(manager.state.c2s, 3, reason: "The C2S counter must count correctly");

      final ack = XMLNode.xmlns(tag: "a", xmlns: "urn:xmpp:sm:3", attributes: { "h": "3" });
      await manager.runNonzaHandlers(ack);
      expect(manager.getUnackedStanzas().isEmpty, true, reason: "All C2S stanzas have been acknoledged. The queue should be empty.");
      expect(manager.state.s2c, 2, reason: "Sending stanzas must not change the S2C counter");

      // Send a stanza which we will not acknowledge
      runOutgoingStanzaHandlers(manager, stanza);
      expect(manager.state.c2s, 4, reason: "Sending a stanza must increment the C2S counter");
      await manager.runNonzaHandlers(ack);
      // NOTE: In production this should be 4 since we have a Stream broadcasting an
      //       StanzaSent event. We don't here.
      expect(manager.state.c2s, 3, reason: "Retransmitting a stanza must not change the counter");

      await manager.onStreamResumed(3);

      expect(compareXMLNodes(lastSentStanza, stanza), true, reason: "Unacknowledged C2S stanzas must be retransmitted");
  });

  test("Resending stanzas after a stream resumption", () async {
      Stanza lastSentStanza = Stanza(tag: "message");

      final attributes = XmppManagerAttributes(
        sendStanza: (stanza, { StanzaFromType addFrom = StanzaFromType.full, bool addId = true, bool retransmitted = false, bool awaitable = true }) async {
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
          jid: JID.fromString("hallo@example.server"),
          password: "password",
          useDirectTLS: true,
          allowPlainAuth: false,
        ),
        isStreamFeatureSupported: (feat) => false,
        isFeatureSupported: (_) => false,
        getFullJID: () => JID.fromString("hallo@example.server/uwu")
      );
      final manager = StreamManagementManager();
      manager.register(attributes);

      // Send some stanzas
      runOutgoingStanzaHandlers(manager, stanza);
      runOutgoingStanzaHandlers(manager, stanza);
      runOutgoingStanzaHandlers(manager, stanza);

      // Simulate a resumption
      await manager.onStreamResumed(2);

      expect(compareXMLNodes(lastSentStanza, stanza), true, reason: "Unacked stanzas should be retransmitted on stream resumption");
  });

  test("Test stream management enablement without resumption", () {
      // NOTE: This test is to ensure that the manager does not immediately freak out if
      //       we give it no resumption id.
      final attributes = XmppManagerAttributes(
        sendStanza: (stanza, { StanzaFromType addFrom = StanzaFromType.full, bool addId = true, bool retransmitted = false, bool awaitable = true }) async => stanza,
        sendNonza: (nonza) {},
        sendEvent: (event) {},
        sendRawXml: (raw) {},
        getManagerById: (id) => null,
        getConnectionSettings: () => ConnectionSettings(
          jid: JID.fromString("hallo@example.server"),
          password: "password",
          useDirectTLS: true,
          allowPlainAuth: false,
        ),
        isStreamFeatureSupported: (feat) => false,
        isFeatureSupported: (_) => false,
        getFullJID: () => JID.fromString("hallo@example.server/uwu")
      );
      final manager = StreamManagementManager();
      manager.register(attributes);
      manager.onXmppEvent(StreamManagementEnabledEvent(resource: "aaaa"));

      expect(manager.state.c2s, 0);
      expect(manager.state.s2c, 0);
  });
  
  test("Test stream management essentials", () async {
      final attributes = XmppManagerAttributes(
        sendStanza: (stanza, { StanzaFromType addFrom = StanzaFromType.full, bool addId = true, bool retransmitted = false, bool awaitable = true }) async => stanza,
        sendNonza: (nonza) {},
        sendEvent: (event) {},
        sendRawXml: (raw) {},
        getManagerById: (id) => null,
        getConnectionSettings: () => ConnectionSettings(
          jid: JID.fromString("hallo@example.server"),
          password: "password",
          useDirectTLS: true,
          allowPlainAuth: false,
        ),
        isStreamFeatureSupported: (feat) => false,
        isFeatureSupported: (_) => false,
        getFullJID: () => JID.fromString("hallo@example.server/uwu")
      );
      final manager = StreamManagementManager();
      manager.register(attributes);
      manager.onXmppEvent(StreamManagementEnabledEvent(id: "abc123", resource: "aaaa"));

      manager.setState(StreamManagementState(140, 149));

      // [Connection lost, reconnecting]
      // <== <resumed h='150' ... />
      manager.onXmppEvent(ConnectingEvent());
      expect(manager.isStreamManagementEnabled(), false);

      await manager.onStreamResumed(150);

      expect(manager.state.c2s, 150);
      expect(manager.state.s2c, 149);
  });
}
