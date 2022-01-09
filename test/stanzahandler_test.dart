import "package:test/test.dart";

import "package:moxxyv2/xmpp/stanzas/stanza.dart";
import "package:moxxyv2/xmpp/stanzas/handlers.dart";
import "package:moxxyv2/xmpp/stringxml.dart";

final stanza1 = Stanza.iq(children: [
    XMLNode.xmlns(tag: "tag", xmlns: "owo")
]);
final stanza2 = Stanza.iq(children: [
    XMLNode.xmlns(tag: "some-other-tag", xmlns: "owo")
]);

void main() {
  test("match all", () {
      final handler = StanzaHandler(callback: (_, __) => true);

      expect(handler.matches(Stanza.iq()), true);
      expect(handler.matches(Stanza.message()), true);
      expect(handler.matches(Stanza.presence()), true);
      expect(handler.matches(stanza1), true);
      expect(handler.matches(stanza2), true);
  });
  test("xmlns matching", () {
      final handler = StanzaHandler(callback: (_, __) => true, xmlns: "owo");

      expect(handler.matches(Stanza.iq()), false);
      expect(handler.matches(Stanza.message()), false);
      expect(handler.matches(Stanza.presence()), false);
      expect(handler.matches(stanza1), true);
      expect(handler.matches(stanza2), true);
  });
  test("stanzaTag matching", () {
      final handler = StanzaHandler(callback: (_, __) => true, stanzaTag: "iq");

      expect(handler.matches(Stanza.iq()), true);
      expect(handler.matches(Stanza.message()), false);
      expect(handler.matches(Stanza.presence()), false);
      expect(handler.matches(stanza1), true);
      expect(handler.matches(stanza2), true);
  });
  test("tagName matching", () {
      final handler = StanzaHandler(callback: (_, __) => true, tagName: "tag");

      expect(handler.matches(Stanza.iq()), false);
      expect(handler.matches(Stanza.message()), false);
      expect(handler.matches(Stanza.presence()), false);
      expect(handler.matches(stanza1), true);
      expect(handler.matches(stanza2), false);
  });
  test("combined matching", () {
      final handler = StanzaHandler(callback: (_, __) => true, tagName: "tag", stanzaTag: "iq", xmlns: "owo");

      expect(handler.matches(Stanza.iq()), false);
      expect(handler.matches(Stanza.message()), false);
      expect(handler.matches(Stanza.presence()), false);
      expect(handler.matches(stanza1), true);
      expect(handler.matches(stanza2), false);
  });
}
