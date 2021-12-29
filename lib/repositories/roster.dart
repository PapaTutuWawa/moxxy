import "dart:collection";

import "package:moxxyv2/redux/state.dart";
import "package:moxxyv2/redux/roster/actions.dart";
import "package:moxxyv2/db/roster.dart" as db;

import "package:redux/redux.dart";
import "package:isar/isar.dart";
import "package:get_it/get_it.dart";

import "package:moxxyv2/isar.g.dart";

class RosterRepository {
  final Isar isar;
  final Store<MoxxyState> store;

  RosterRepository({ required this.isar, required this.store });

  Future<void> loadRosterFromDatabase() async {
    var roster = await this.isar.rosterItems.where().findAll();

    roster.forEach((item) {
        this.store.dispatch(AddRosterItemAction(
            avatarUrl: item.avatarUrl,
            jid: item.jid,
            title: item.title,
            triggeredByDatabase: true
        ));
    });
  }

  Future<void> addRosterItem(db.RosterItem rosterItem) async {
    print("addRosterItem");
    await this.isar.writeTxn((isar) async {
        await isar.rosterItems.put(rosterItem);
        print("DONE");
    });
  }
  
  Future<void> addRosterItemFromAction(AddRosterItemAction action) async {
    final rosterItem = db.RosterItem()
      ..jid = action.jid
      ..title = action.title
      ..avatarUrl = action.avatarUrl;

    await this.isar.writeTxn((isar) async {
        await isar.rosterItems.put(rosterItem);
        print("DONE");
    });
  }
}
