import "package:moxxyv2/service/roster.dart";
import "package:moxxyv2/xmpp/roster.dart";
import "package:moxxyv2/shared/models/roster.dart";

import "package:test/test.dart";

void main() {
  final localRoster = [
    const RosterItem(id: 0, jid: "hallo@server.example", title: "", subscription: "none", groups: [], avatarUrl: "", ask: "")
  ];

  test("Test if the roster diff works for roster pushes", () async {
      final result = await rosterDiff(localRoster, [
          XmppRosterItem(
            jid: "hallo@server.example",
            subscription: "remove",
          ) 
      ], true);

      expect(result.removed, [ "hallo@server.example" ]);
      expect(result.modified.length, 0);
      expect(result.added.length, 0);

      final result2 = await rosterDiff(localRoster, [
          XmppRosterItem(
            jid: "hallo@server.example",
            subscription: "both",
          ) 
      ], true);

      expect(result2.removed.length, 0);
      expect(result2.added.length, 0);
      expect(result2.modified, 1);
      expect(result2.modified[0].subscription, "both");
  });
}
