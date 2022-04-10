import "package:moxxyv2/xmpp/connection.dart";
import "package:moxxyv2/xmpp/settings.dart";
import "package:moxxyv2/xmpp/namespaces.dart";
import "package:moxxyv2/xmpp/stringxml.dart";
import "package:moxxyv2/xmpp/jid.dart";
import "package:moxxyv2/xmpp/managers/attributes.dart";
import "package:moxxyv2/xmpp/xeps/xep_0352.dart";

import "package:test/test.dart";

void main() {
  group("Test the XEP-0352 implementation", () {
      test("Test setting the CSI state when CSI is unsupported", () {
          bool nonzaSent = false;
          final csi = CSIManager();
          csi.register(XmppManagerAttributes(
              sendStanza: (_, { StanzaFromType addFrom = StanzaFromType.full, bool addId = true, bool retransmitted = false, bool awaitable = true }) async => XMLNode(tag: "hallo"),
              sendEvent: (event) {},
              sendNonza: (nonza) {
                nonzaSent = true;
              },
              sendRawXml: (_) {},
              getConnectionSettings: () => ConnectionSettings(
                jid: JID.fromString("some.user@example.server"),
                password: "password",
                useDirectTLS: true,
                allowPlainAuth: false,
              ),
              getManagerById: (_) => null,
              isStreamFeatureSupported: (_) => false,
              isFeatureSupported: (_) => false,
              getFullJID: () => JID.fromString("some.user@example.server/aaaaa")
          ));

          csi.setActive();
          csi.setInactive();

          expect(nonzaSent, false, reason: "Expected that no nonza is sent");
      });
      test("Test setting the CSI state when CSI is supported", () {
          final csi = CSIManager();
          csi.register(XmppManagerAttributes(
              sendStanza: (_, { StanzaFromType addFrom = StanzaFromType.full, bool addId = true, bool retransmitted = false, bool awaitable = true }) async => XMLNode(tag: "hallo"),
              sendEvent: (event) {},
              sendNonza: (nonza) {
                expect(nonza.attributes["xmlns"] == csiXmlns, true, reason: "Expected only nonzas with XMLNS '$csiXmlns'");
              },
              sendRawXml: (_) {},
              getConnectionSettings: () => ConnectionSettings(
                jid: JID.fromString("some.user@example.server"),
                password: "password",
                useDirectTLS: true,
                allowPlainAuth: false,
              ),
              getManagerById: (_) => null,
              isStreamFeatureSupported: (xmlns) => xmlns == csiXmlns,
              isFeatureSupported: (_) => false,
              getFullJID: () => JID.fromString("some.user@example.server/aaaaa")
          ));

          csi.setActive();
          csi.setInactive();
      });
  });
}
