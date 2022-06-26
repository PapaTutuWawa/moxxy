import "package:test/test.dart";

import "package:moxxyv2/xmpp/stanza.dart";
import "package:moxxyv2/xmpp/stringxml.dart";

void main() {
  test("Make sure reply does not copy the children", () {
      final stanza = Stanza.iq(
        to: "hallo",
        from: "world",
        id: "abc123",
        type: "get",
        children: [
          XMLNode(tag: "test-tag"),
          XMLNode(tag: "test-tag2")
        ]
      );

      final reply = stanza.reply();

      expect(reply.children, []);
      expect(reply.type, "result");
      expect(reply.from, stanza.to);
      expect(reply.to, stanza.from);
      expect(reply.id, stanza.id);
  });

  test("Make sure reply includes the new children", () {
      final stanza = Stanza.iq(
        to: "hallo",
        from: "world",
        id: "abc123",
        type: "get",
        children: [
          XMLNode(tag: "test-tag"),
          XMLNode(tag: "test-tag2")
        ]
      );

      final reply = stanza.reply(
        children: [
          XMLNode.xmlns(
            tag: "test",
            xmlns: "test"
          )
        ]
      );

      expect(reply.children.length, 1);
      expect(reply.firstTag("test") != null, true);
  });
}
