import "package:moxxyv2/xmpp/connection.dart";
import "package:moxxyv2/xmpp/jid.dart";
import "package:moxxyv2/xmpp/settings.dart";
import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/reconnect.dart";
import "package:moxxyv2/xmpp/managers/attributes.dart";
import "package:moxxyv2/xmpp/xeps/xep_0280.dart";

import "../helpers/xmpp.dart";

import "package:test/test.dart";

void main() {
  test("Test if we're vulnerable against CVE-2020-26547 style vulnerabilities", () async {
      final attributes = XmppManagerAttributes(
        sendStanza: (stanza, { StanzaFromType addFrom = StanzaFromType.full, bool addId = true, bool retransmitted = false, bool awaitable = true }) async {
          // ignore: avoid_print
          print("==> " + stanza.toXml());
          return XMLNode(tag: "iq", attributes: { "type": "result" });
        },
        sendNonza: (nonza) {},
        sendEvent: (event) {},
        sendRawXml: (raw) {},
        getManagerById: (id) => null,
        getConnectionSettings: () => ConnectionSettings(
          jid: JID.fromString("bob@xmpp.example"),
          password: "password",
          useDirectTLS: true,
          allowPlainAuth: false,
        ),
        isFeatureSupported: (_) => false,
        getFullJID: () => JID.fromString("bob@xmpp.example/uwu"),
        getSocket: () => StubTCPSocket(play: []),
        getConnection: () => XmppConnection(TestingReconnectionPolicy()),
        getNegotiatorById: (id) => null,
      );
      final manager = CarbonsManager();
      manager.register(attributes);
      await manager.enableCarbons();

      expect(manager.isCarbonValid(JID.fromString("mallory@evil.example")), false);
      expect(manager.isCarbonValid(JID.fromString("bob@xmpp.example")), true);
      expect(manager.isCarbonValid(JID.fromString("bob@xmpp.example/abc")), false);
  });
}
