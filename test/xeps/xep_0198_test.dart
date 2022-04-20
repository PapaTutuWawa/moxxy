import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/events.dart";
import "package:moxxyv2/xmpp/stanza.dart";
import "package:moxxyv2/xmpp/settings.dart";
import "package:moxxyv2/xmpp/jid.dart";
import "package:moxxyv2/xmpp/connection.dart";
import "package:moxxyv2/xmpp/managers/attributes.dart";
import "package:moxxyv2/xmpp/managers/data.dart";
import "package:moxxyv2/xmpp/xeps/xep_0198/xep_0198.dart";

import "package:test/test.dart";

Future<void> runIncomingStanzaHandlers(StreamManagementManager man, Stanza stanza) async {
  for (final handler in man.getIncomingStanzaHandlers()) {
    if (handler.matches(stanza)) await handler.callback(stanza, StanzaHandlerData(false, stanza));
  }
}

Future<void> runOutgoingStanzaHandlers(StreamManagementManager man, Stanza stanza) async {
  for (final handler in man.getOutgoingPostStanzaHandlers()) {
    if (handler.matches(stanza)) await handler.callback(stanza, StanzaHandlerData(false, stanza));
  }
}

XmppManagerAttributes mkAttributes(void Function(Stanza) callback) {
  return XmppManagerAttributes(
    sendStanza: (stanza, { StanzaFromType addFrom = StanzaFromType.full, bool addId = true, bool retransmitted = false, bool awaitable = true }) async {
      callback(stanza);

      return Stanza.message();
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
}

XMLNode mkAck(int h) => XMLNode.xmlns(tag: "a", xmlns: "urn:xmpp:sm:3", attributes: { "h": h.toString() });

void main() {
  final stanza = Stanza(
    to: "some.user@server.example",
    tag: "message"
  );

  /*test("Test Stream Management", () async {
      Stanza lastSentStanza = Stanza(tag: "message");

      final attributes = mkAttributes((stanza) {
          // ignore: avoid_print
          print("==> " + stanza.toXml());
          lastSentStanza = stanza;
      });
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

      final attributes = mkAttributes((stanza) {
          // ignore: avoid_print
          print("==> " + stanza.toXml());
          lastSentStanza = stanza;
      });
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
      final attributes = mkAttributes((_) {});
      final manager = StreamManagementManager();
      manager.register(attributes);
      manager.onXmppEvent(StreamManagementEnabledEvent(resource: "aaaa"));

      expect(manager.state.c2s, 0);
      expect(manager.state.s2c, 0);
  });
  
  test("Test stream management essentials", () async {
      final attributes = mkAttributes((_) {});
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
  });*/

  test("Test stream with SM enablement", () async {
      final attributes = mkAttributes((_) {});
      final manager = StreamManagementManager();
      manager.register(attributes);

      // [...]
      // <enable />
      // <enabled />
      await manager.onXmppEvent(StreamManagementEnabledEvent(resource: "hallo"));
      expect(manager.state.c2s, 0);
      expect(manager.state.s2c, 0);

      expect(manager.isStreamManagementEnabled(), true);

      // Send a stanza 5 times
      for (int i = 0; i < 5; i++) {
        await runOutgoingStanzaHandlers(manager, stanza);
      }
      expect(manager.state.c2s, 5);

      // Receive 3 stanzas
      for (int i = 0; i < 3; i++) {
        await runIncomingStanzaHandlers(manager, stanza);
      }
      expect(manager.state.s2c, 3);
  });

  group("Acking", () {
      test("Test completely clearing the queue", () async {
          final attributes = mkAttributes((_) {});
          final manager = StreamManagementManager();
          manager.register(attributes);

          await manager.onXmppEvent(StreamManagementEnabledEvent(resource: "hallo"));

          // Send a stanza 5 times
          for (int i = 0; i < 5; i++) {
            await runOutgoingStanzaHandlers(manager, stanza);
          }

          // <a h='5'/>
          await manager.runNonzaHandlers(mkAck(5));
          expect(manager.getUnackedStanzas().length, 0);
      });
      test("Test partially clearing the queue", () async {
          final attributes = mkAttributes((_) {});
          final manager = StreamManagementManager();
          manager.register(attributes);

          await manager.onXmppEvent(StreamManagementEnabledEvent(resource: "hallo"));
          
          // Send a stanza 5 times
          for (int i = 0; i < 5; i++) {
            await runOutgoingStanzaHandlers(manager, stanza);
          }

          // <a h='3'/>
          await manager.runNonzaHandlers(mkAck(3));
          expect(manager.getUnackedStanzas().length, 2);
      });
      test("Send an ack with h > c2s", () async {
          final attributes = mkAttributes((_) {});
          final manager = StreamManagementManager();
          manager.register(attributes);

          await manager.onXmppEvent(StreamManagementEnabledEvent(resource: "hallo"));
          
          // Send a stanza 5 times
          for (int i = 0; i < 5; i++) {
            await runOutgoingStanzaHandlers(manager, stanza);
          }

          // <a h='3'/>
          await manager.runNonzaHandlers(mkAck(6));
          expect(manager.getUnackedStanzas().length, 0);
          expect(manager.state.c2s, 6);
      });
      test("Send an ack with h < c2s", () async {
          final attributes = mkAttributes((_) {});
          final manager = StreamManagementManager();
          manager.register(attributes);

          await manager.onXmppEvent(StreamManagementEnabledEvent(resource: "hallo"));
          
          // Send a stanza 5 times
          for (int i = 0; i < 5; i++) {
            await runOutgoingStanzaHandlers(manager, stanza);
          }

          // <a h='3'/>
          await manager.runNonzaHandlers(mkAck(3));
          expect(manager.getUnackedStanzas().length, 2);
          expect(manager.state.c2s, 5);
      });
  });

  group("Stream resumption", () {
      test("Stanza retransmission", () async {
          int stanzaCount = 0;
          final attributes = mkAttributes((_) {
              stanzaCount++;
          });
          final manager = StreamManagementManager();
          manager.register(attributes);

          await manager.onXmppEvent(StreamManagementEnabledEvent(resource: "hallo"));

          // Send 5 stanzas
          for (int i = 0; i < 5; i++) {
            await runOutgoingStanzaHandlers(manager, stanza);
          }

          // Only ack 3
          // <a h='3' />
          await manager.runNonzaHandlers(mkAck(3));
          expect(manager.getUnackedStanzas().length, 2);

          // Lose connection
          // [ Reconnect ]
          await manager.onXmppEvent(StreamResumedEvent(h: 3));

          expect(stanzaCount, 2);
      });
      test("Resumption with prior state", () async {
          int stanzaCount = 0;
          final attributes = mkAttributes((_) {
              stanzaCount++;
          });
          final manager = StreamManagementManager();
          manager.register(attributes);

          // [ ... ]
          await manager.onXmppEvent(StreamManagementEnabledEvent(resource: "hallo"));
          manager.setState(manager.state.copyWith(c2s: 150, s2c: 70));

          // Send some stanzas but don't ack them
          for (int i = 0; i < 5; i++) {
            await runOutgoingStanzaHandlers(manager, stanza);
          }
          expect(manager.getUnackedStanzas().length, 5);
          
          // Lose connection
          // [ Reconnect ]
          await manager.onXmppEvent(StreamResumedEvent(h: 150));
          expect(manager.getUnackedStanzas().length, 0);
          expect(stanzaCount, 5);
      });
  });
}
