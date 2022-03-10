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
}
