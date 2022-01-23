import "package:moxxyv2/xmpp/managers/attributes.dart";
import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/events.dart";
import "package:moxxyv2/xmpp/stanzas/stanza.dart";
import "package:moxxyv2/xmpp/settings.dart";
import "package:moxxyv2/xmpp/jid.dart";
import "package:moxxyv2/xmpp/xeps/xep_0198.dart";

import "package:test/test.dart";

void main() {
  // TODO: Test resumption
  test("Test Stream Management", () {
      final attributes = XmppManagerAttributes(
        // ignore: avoid_print
        log: (msg) => print(msg),
        sendStanza: (stanza, { bool addFrom = true, bool addId = true }) async {
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
      final stanza = Stanza(
        to: "some.user@server.example",
        tag: "message"
      );
      manager.getStanzaHandlers().forEach((handler) {
          if (handler.matches(stanza)) {
            handler.callback(stanza);
          }
      });
      expect(manager.getServerStanzaSeq(), 1);

      // Send some fake stanzas
      manager.onXmppEvent(StanzaSentEvent(stanza: stanza));
      manager.onXmppEvent(StanzaSentEvent(stanza: stanza));
      manager.onXmppEvent(StanzaSentEvent(stanza: stanza));
      expect(manager.getClientStanzaSeq(), 3);

      manager.getNonzaHandlers().forEach((handler) {
          if (handler.matches(XMLNode.xmlns(tag: "a", xmlns: "urn:xmpp:sm:3", attributes: { "h": "2" }))) {
            handler.callback(XMLNode.xmlns(tag: "a", xmlns: "urn:xmpp:sm:3", attributes: { "h": "2" }));
          }
      });
      expect(manager.getUnackedStanzas().isEmpty, true);
      expect(manager.getServerStanzaSeq(), 1);
  });
}
