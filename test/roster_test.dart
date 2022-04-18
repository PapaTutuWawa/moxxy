import "package:moxxyv2/service/roster.dart";
import "package:moxxyv2/xmpp/roster.dart";
import "package:moxxyv2/shared/helpers.dart";
import "package:moxxyv2/shared/models/roster.dart";

import "package:test/test.dart";

AddRosterItemFunction mkAddRosterItem(void Function(String) callback) {
  return (
    String avatarUrl,
    String avatarHash,
    String jid,
    String title,
    String subscription,
    String ask,
    {
      List<String> groups = const []
    }
  ) async {
    callback(jid);
    return await addRosterItemFromData(
      avatarUrl,
      avatarHash,
      jid,
      title,
      subscription,
      ask,
      groups: groups
    );
  };
}

Future<RosterItem> addRosterItemFromData(
  String avatarUrl,
  String avatarHash,
  String jid,
  String title,
  String subscription,
  String ask,
  {
    List<String> groups = const []
  }
) async => RosterItem(
  0,
  avatarUrl,
  avatarHash,
  jid,
  title,
  subscription,
  ask,
  groups
);

UpdateRosterItemFunction mkRosterUpdate(List<RosterItem> roster) {
  return (
    int id, {
      String? avatarUrl,
      String? avatarHash,
      String? title,
      String? subscription,
      String? ask,
      List<String>? groups
    }
  ) async {
    final item = firstWhereOrNull(roster, (RosterItem item) => item.id == id)!;
    return item.copyWith(
      avatarUrl: avatarUrl ?? item.avatarUrl,
      avatarHash: avatarHash ?? item.avatarHash,
      title: title ?? item.title,
      subscription: subscription ?? item.subscription,
      ask: ask ?? item.ask,
      groups: groups ?? item.groups
    );
  };
}

void main() {
  final localRosterSingle = [
    RosterItem(
      0,
      "",
      "",
      "hallo@server.example",
      "hallo",
      "none",
      "",
      []
    )
  ];
  final localRosterEmpty = [];
  final localRosterDouble = [
    RosterItem(
      0,
      "",
      "",
      "hallo@server.example",
      "hallo",
      "none",
      "",
      []
    ),
    RosterItem(
      1,
      "",
      "",
      "welt@different.server.example",
      "welt",
      "from",
      "",
      [ "Friends" ]
    )
  ];

  group("Test roster pushes", () {
      test("Test removing an item", () async {
          bool removeCalled = false;
          bool addCalled = false;
          final result = await processRosterDiff(
            localRosterDouble,
            [
              XmppRosterItem(
                jid: "hallo@server.example", subscription: "remove",
              ) 
            ],
            true,
            mkAddRosterItem((_) { addCalled = true; }),
            mkRosterUpdate(localRosterDouble),
            (jid) async {
              if (jid == "hallo@server.example") {
                removeCalled = true;
              }
            },
            (_) async => null,
            (_, { String? id }) async {}
          );

          expect(result.removed, [ "hallo@server.example" ]);
          expect(result.modified.length, 0);
          expect(result.added.length, 0);
          expect(removeCalled, true);
          expect(addCalled, false);
      });

      test("Test adding an item", () async {
          bool removeCalled = false;
          bool addCalled = false;
          final result = await processRosterDiff(
            localRosterSingle,
            [
              XmppRosterItem(
                jid: "welt@different.server.example",
                subscription: "from",
              ) 
            ],
            true,
            mkAddRosterItem(
              (jid) {
                if (jid == "welt@different.server.example") {
                  addCalled = true;
                }
              }
            ),
            mkRosterUpdate(localRosterSingle),
            (_) async { removeCalled = true; },
            (_) async => null,
            (_, { String? id }) async {}
          );

          expect(result.removed, [ ]);
          expect(result.modified.length, 0);
          expect(result.added.length, 1);
          expect(result.added.first.subscription, "from");
          expect(removeCalled, false);
          expect(addCalled, true);
      });

      test("Test modifying an item", () async {
          bool removeCalled = false;
          bool addCalled = false;
          final result = await processRosterDiff(
            localRosterDouble,
            [
              XmppRosterItem(
                jid: "welt@different.server.example",
                subscription: "both",
                name: "The World"
              ) 
            ],
            true,
            mkAddRosterItem((_) { addCalled = false; }),
            mkRosterUpdate(localRosterDouble),
            (_) async { removeCalled = true; },
            (_) async => null,
            (_, { String? id }) async {}
          );

          expect(result.removed, [ ]);
          expect(result.modified.length, 1);
          expect(result.added.length, 0);
          expect(result.modified.first.subscription, "both");
          expect(result.modified.first.jid, "welt@different.server.example");
          expect(result.modified.first.title, "The World");
          expect(removeCalled, false);
          expect(addCalled, false);
      });
  });

  group("Test roster requests", () {
      test("Test removing an item", () async {
          bool removeCalled = false;
          bool addCalled = false;
          final result = await processRosterDiff(
            localRosterSingle,
            [],
            false,
            mkAddRosterItem((_) { addCalled = true; }),
            mkRosterUpdate(localRosterDouble),
            (jid) async {
              if (jid == "hallo@server.example") {
                removeCalled = true;
              }
            },
            (_) async => null,
            (_, { String? id }) async {}
          );

          expect(result.removed, [ "hallo@server.example" ]);
          expect(result.modified.length, 0);
          expect(result.added.length, 0);
          expect(removeCalled, true);
          expect(addCalled, false);
      });

      test("Test adding an item", () async {
          bool removeCalled = false;
          bool addCalled = false;
          final result = await processRosterDiff(
            localRosterSingle,
            [
              XmppRosterItem(
                jid: "hallo@server.example",
                name: "hallo",
                subscription: "none"
              ),
              XmppRosterItem(
                jid: "welt@different.server.example",
                subscription: "both"
              )
            ],
            false,
            mkAddRosterItem(
              (jid) {
                if (jid == "welt@different.server.example") {
                  addCalled = true;
                }
              }
            ),
            mkRosterUpdate(localRosterSingle),
            (_) async { removeCalled = true; },
            (_) async => null,
            (_, { String? id }) async {}
          );

          expect(result.removed, [ ]);
          expect(result.modified.length, 0);
          expect(result.added.length, 1);
          expect(result.added.first.subscription, "both");
          expect(removeCalled, false);
          expect(addCalled, true);
      });

      test("Test modifying an item", () async {
          bool removeCalled = false;
          bool addCalled = false;
          final result = await processRosterDiff(
            localRosterSingle,
            [
              XmppRosterItem(
                jid: "hallo@server.example",
                subscription: "both",
                name: "Hallo Welt"
              ) 
            ],
            false,
            mkAddRosterItem((_) { addCalled = false; }),
            mkRosterUpdate(localRosterDouble),
            (_) async { removeCalled = true; },
            (_) async => null,
            (_, { String? id }) async {}
          );

          expect(result.removed, [ ]);
          expect(result.modified.length, 1);
          expect(result.added.length, 0);
          expect(result.modified.first.subscription, "both");
          expect(result.modified.first.jid, "hallo@server.example");
          expect(result.modified.first.title, "Hallo Welt");
          expect(removeCalled, false);
          expect(addCalled, false);
      });
  });
}
