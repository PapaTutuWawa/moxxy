import "dart:async";

import "package:moxxyv2/models/roster.dart";
import "package:moxxyv2/xmpp/connection.dart";
import "package:moxxyv2/xmpp/managers/namespaces.dart";
import "package:moxxyv2/service/repositories/database.dart";

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

    await GetIt.I.get<XmppConnection>().getManagerById(rosterManager)!.addToRoster(jid, title);
    await GetIt.I.get<XmppConnection>().getManagerById(rosterManager)!.sendSubscriptionRequest(jid);

    sendData({
        "type": "RosterItemAddedEvent",
        "item": item.toJson()
    });

    return item;
  }

  Future<void> removeFromRoster(String jid, { bool nullOkay = false }) async {
    await GetIt.I.get<DatabaseRepository>().removeRosterItemByJid(jid, nullOkay: nullOkay);

    /* TODO: Maybe uncomment
    sendData({
        "type": "RosterItemRemovedEvent",
        "jid": jid
    });
    */
  }

  Future<void> requestRoster() async {
    final result = await GetIt.I.get<XmppConnection>().getManagerById(rosterManager)!.requestRoster();

    // TODO: Use logging function
    // ignore: avoid_print
    print("requestRoster done");
    
    if (result == null || result.items.isEmpty) {
      // TODO: Use logging function
      // ignore: avoid_print
      print("No roster items received");
      return;
    }

    // TODO: Update updated items
    // NOTE: Removed items will be handled in connection.dart
    /* TODO
    final newItems = result.items.where((item) => firstWhereOrNull(store.state.roster, (RosterItem i) => i.jid == item.jid) == null);

    
    final newAddedItems = await Future.wait(newItems.map((item) async => await addRosterItemFromData("", item.jid, item.name ?? item.jid.split("@")[0])));
    newAddedItems.forEach((item) => _cache[item.jid] = item);
    store.dispatch(AddMultipleRosterItemsAction(items: newAddedItems.toList()));
    */
  }
}
