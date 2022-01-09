import "dart:collection";
import "dart:async";

import "package:moxxyv2/helpers.dart";
import "package:moxxyv2/redux/state.dart";
import "package:moxxyv2/redux/roster/actions.dart";
import "package:moxxyv2/db/roster.dart" as db;
import "package:moxxyv2/models/roster.dart";
import "package:moxxyv2/xmpp/connection.dart";
import "package:moxxyv2/xmpp/roster.dart";

import "package:redux/redux.dart";
import "package:isar/isar.dart";
import "package:get_it/get_it.dart";

import "package:moxxyv2/isar.g.dart";

class RosterRepository {
  final Isar isar;
  final Store<MoxxyState> store;
  final Map<String, RosterItem> _cache;
  
  RosterRepository({ required this.isar, required this.store }) : _cache = Map();

  bool isInRoster(String jid) {
    return this._cache.containsKey(jid);
  }
  
  Future<void> loadRosterFromDatabase() async {
    final roster = await this.isar.rosterItems.where().findAll();
    final items = roster.map((item) => RosterItem(
        avatarUrl: item.avatarUrl,
        jid: item.jid,
        title: item.title,
        id: item.id!
    ));
    this._cache.clear();
    items.forEach((item) => this._cache[item.jid] = item);
        
    this.store.dispatch(AddMultipleRosterItemsAction(
        items: items.toList()
    ));
  }

  Future<RosterItem> addToRoster(String avatarUrl, String jid, String title) async {
    final item = await this.addRosterItemFromData(avatarUrl, jid, title);
    this._cache[jid] = item;
    await GetIt.I.get<XmppConnection>().addToRoster(jid, title);
    await GetIt.I.get<XmppConnection>().sendSubscriptionRequest(jid);
    return item;
  }

  Future<void> removeFromRoster(String jid, { bool nullOkay = false }) async {
    final item = this._cache[jid];
    print("RosterRepository::removeFromRoster");
    
    if (item != null) {
      await this.isar.writeTxn((isar) async {
          await isar.rosterItems.delete(item.id);
      });
      this._cache.remove(jid);
    } else if (!nullOkay) {
      print("RosterRepository::removeFromRoster: Could not find $jid in roster state");
    }
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

    
    final newAddedItems = await Future.wait(newItems.map((item) async => await this.addRosterItemFromData("", item.jid, item.name ?? item.jid.split("@")[0])));
    newAddedItems.forEach((item) => this._cache[item.jid] = item);
    this.store.dispatch(AddMultipleRosterItemsAction(items: newAddedItems.toList()));
  }

  Future<RosterItem> addRosterItemFromData(String avatarUrl, String jid, String title) async {
    final rosterItem = db.RosterItem()
      ..jid = jid
      ..title = title
      ..avatarUrl = avatarUrl;

    await this.isar.writeTxn((isar) async {
        await isar.rosterItems.put(rosterItem);
        print("DONE");
    });

    return RosterItem(
      jid: jid,
      avatarUrl: avatarUrl,
      title: title,
      id: rosterItem.id!
    );
  }
}
