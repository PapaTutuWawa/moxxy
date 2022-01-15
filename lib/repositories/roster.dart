import "dart:collection";
import "dart:async";

import "package:moxxyv2/helpers.dart";
import "package:moxxyv2/db/roster.dart";
import "package:moxxyv2/models/roster.dart";
import "package:moxxyv2/xmpp/connection.dart";
import "package:moxxyv2/xmpp/roster.dart";
import "package:moxxyv2/repositories/database.dart";

import "package:get_it/get_it.dart";


class RosterRepository {
  final void Function(Map<String, dynamic>) sendData;
  
  RosterRepository({ required this.sendData });

  Future<bool> isInRoster(String jid) async {
    return await GetIt.I.get<DatabaseRepository>().isInRoster(jid);
  }

  Future<void> loadRosterFromDatabase() async {
    await GetIt.I.get<DatabaseRepository>().loadRosterItems(notify: true);
  }
  
  Future<RosterItem> addToRoster(String avatarUrl, String jid, String title) async {
    final item = await GetIt.I.get<DatabaseRepository>().addRosterItemFromData(avatarUrl, jid, title);

    await GetIt.I.get<XmppConnection>().addToRoster(jid, title);
    await GetIt.I.get<XmppConnection>().sendSubscriptionRequest(jid);

    this.sendData({
        "type": "RosterItemAddedEvent",
        "item": item.toJson()
    });

    return item;
  }

  Future<void> removeFromRoster(String jid, { bool nullOkay = false }) async {
    await GetIt.I.get<DatabaseRepository>().removeRosterItemByJid(jid, nullOkay: nullOkay);

    this.sendData({
        "type": "RosterItemRemovedEvent",
        "jid": jid
    });
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
      /* TODO
      this.store.dispatch(SaveCurrentRosterVersionAction(ver: result.ver!));
      */
    }

    // TODO: Update updated items
    // NOTE: Removed items will be handled in connection.dart
    /* TODO
    final newItems = result.items.where((item) => firstWhereOrNull(this.store.state.roster, (RosterItem i) => i.jid == item.jid) == null);

    
    final newAddedItems = await Future.wait(newItems.map((item) async => await this.addRosterItemFromData("", item.jid, item.name ?? item.jid.split("@")[0])));
    newAddedItems.forEach((item) => this._cache[item.jid] = item);
    this.store.dispatch(AddMultipleRosterItemsAction(items: newAddedItems.toList()));
    */
  }
}
