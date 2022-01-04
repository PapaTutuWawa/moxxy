import "dart:collection";

import "package:moxxyv2/helpers.dart";
import "package:moxxyv2/redux/state.dart";
import "package:moxxyv2/redux/roster/actions.dart";
import "package:moxxyv2/db/roster.dart" as db;
import "package:moxxyv2/models/roster.dart";
import "package:moxxyv2/xmpp/connection.dart";

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

    this.store.dispatch(AddMultipleRosterItemsAction(
        items: roster.map((item) => RosterItem(
            avatarUrl: item.avatarUrl,
            jid: item.jid,
            title: item.title,
        )).toList()
    ));
  }

  Future<void> addToRoster(String avatarUrl, String jid, String title) async {
    await this.addRosterItemFromData(avatarUrl, jid, title);
    await GetIt.I.get<XmppConnection>().addToRoster(RosterItem(
        jid: jid,
        title: title,
        avatarUrl: avatarUrl
    ));
  }
  
  Future<void> requestRoster(String? lastVersion) async {
    final result = await GetIt.I.get<XmppConnection>().requestRoster(lastVersion);

    print("requestRoster done");
    
    if (result == null) return;
    if (result.items.isEmpty) {
      print("No roster items received");
    }

    if (result.ver == lastVersion) {
      print("Roster is up-to-date");
      return;
    } else if (result.ver != null){
      print("Got new roster version: " + result.ver!);
      this.store.dispatch(SaveCurrentRosterVersionAction(ver: result.ver!));
    }

    // TODO: Update updated items
    // NOTE: Removed items will be handled in connection.dart
    final newItems = result.items.where((item) => firstWhereOrNull(this.store.state.roster, (RosterItem i) => i.jid == item.jid) == null);

    
    newItems.forEach((item) => this.addRosterItemFromModel(item));
    this.store.dispatch(AddMultipleRosterItemsAction(items: newItems.toList()));
  }

  // TODO: make this return RosterItem
  Future<void> addRosterItemFromData(String avatarUrl, String jid, String title) async {
    final rosterItem = db.RosterItem()
      ..jid = jid
      ..title = title
      ..avatarUrl = avatarUrl;

    await this.isar.writeTxn((isar) async {
        await isar.rosterItems.put(rosterItem);
        print("DONE");
    });
  }
  
  Future<void> addRosterItemFromModel(RosterItem item) async {
    final rosterItem = db.RosterItem()
      ..jid = item.jid
      ..title = item.title
      ..avatarUrl = item.avatarUrl;

    await this.isar.writeTxn((isar) async {
        await isar.rosterItems.put(rosterItem);
        print("DONE");
    });
  }
}
