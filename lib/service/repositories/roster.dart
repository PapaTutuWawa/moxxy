import "dart:async";

import "package:moxxyv2/service/repositories/database.dart";
import "package:moxxyv2/shared/models/roster.dart";
import "package:moxxyv2/xmpp/connection.dart";
import "package:moxxyv2/xmpp/managers/namespaces.dart";
import "package:moxxyv2/xmpp/roster.dart";

import "package:get_it/get_it.dart";
import "package:logging/logging.dart";

class RosterRepository {
  final Logger _log;
  final void Function(Map<String, dynamic>) sendData;
  final List<String> _pendingRequests;
  
  RosterRepository({ required this.sendData }) : _pendingRequests = List.empty(growable: true), _log = Logger("RosterRepository");

  /// Returns true if we have a pending request for the jid.
  bool hasPendingRequest(String jid) => _pendingRequests.contains(jid);

  /// Removes a pending request for a jid.
  void removePendingRequest(String jid) => _pendingRequests.remove(jid);
  
  Future<bool> isInRoster(String jid) async {
    return await GetIt.I.get<DatabaseRepository>().isInRoster(jid);
  }

  Future<void> loadRosterFromDatabase() async {
    await GetIt.I.get<DatabaseRepository>().loadRosterItems(notify: true);
  }

  /// Attempts to add an item to the roster by first performing the roster set
  /// and, if it was successful, create the database entry. Returns the
  /// [RosterItem] model object.
  Future<RosterItem> addToRosterWrapper(String avatarUrl, String jid, String title) async {
    _pendingRequests.add(jid);
    final result = await GetIt.I.get<XmppConnection>().getManagerById(rosterManager)!.addToRoster(jid, title);
    if (!result) {
      _pendingRequests.remove(jid);
      // TODO: Signal error?
    }

    await GetIt.I.get<XmppConnection>().getManagerById(rosterManager)!.sendSubscriptionRequest(jid);

    final item = await GetIt.I.get<DatabaseRepository>().addRosterItemFromData(avatarUrl, jid, title);

    sendData({
        "type": "RosterItemAddedEvent",
        "item": item.toJson()
    });

    return item;
  }

  /// Removes the [RosterItem] with jid [jid] from the database.
  Future<void> removeFromRosterDatabase(String jid, { bool nullOkay = false }) async {
    await GetIt.I.get<DatabaseRepository>().removeRosterItemByJid(jid, nullOkay: nullOkay);
  }

  /// Removes the [RosterItem] with jid [jid] from the server-side roster and, if
  /// successful, from the database. If [unsubscribe] is true, then [jid] won't receive
  /// our presence anymore.
  Future<bool> removeFromRosterWrapper(String jid, { bool unsubscribe = true }) async {
    final roster = GetIt.I.get<XmppConnection>().getManagerById(rosterManager)!;
    final result = await roster.removeFromRoster(jid);
    if (!result) {
      // TODO: What _do_ we do?
    }

    await removeFromRosterDatabase(jid);

    if (unsubscribe) {
      await roster.sendUnsubscriptionRequest(jid);
    }

    return true;
  }

  Future<void> requestRoster() async {
    final result = await GetIt.I.get<XmppConnection>().getManagerById(rosterManager)!.requestRoster();

    _log.finest("requestRoster: Done");
    
    if (result == null || result.items.isEmpty) {
      _log.fine("requestRoster: No roster items received");
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

  /// Handles a roster push.
  Future<void> handleRosterPushEvent(RosterPushEvent event) async {
    final item = event.item;

    if (hasPendingRequest(item.jid)) {
      // TODO: This may cause a race condition if we receive another roster push before the one we triggered.
      //       => Check the version of the roster push and ignore the younger one
      // We already know about this item.
      removePendingRequest(item.jid);

      // TODO: Notify the UI
      return;
    }

    final db = GetIt.I.get<DatabaseRepository>();
    final rosterItem = await db.getRosterItemByJid(item.jid);
    final RosterItem modelRosterItem;

    if (item.subscription == "remove") {
      await removeFromRosterWrapper(item.jid);

      sendData({
          "type": "RosterItemRemovedEvent",
          "jid": item.jid
      });
      return;
    }

    // Handle all other cases the same
    if (rosterItem != null) {
      // TODO: Update
      modelRosterItem = await db.updateRosterItem(
        id: rosterItem.id,
      );
    } else {
      modelRosterItem = await db.addRosterItemFromData(
        "",
        item.jid,
        item.jid.split("@")[0]
      );
    }

    sendData({
        "type": "RosterItemModifiedEvent",
        "item": modelRosterItem.toJson()
    });
  }

  // Handle a [RosterItemNotFoundEvent].
  Future<void> handleRosterItemNotFoundEvent(RosterItemNotFoundEvent event) async {
    switch (event.trigger) {
      case RosterItemNotFoundTrigger.remove: {
        sendData({
            "type": "RosterItemRemovedEvent",
            "jid": event.jid
        });
        GetIt.I.get<RosterRepository>().removeFromRosterDatabase(event.jid);
      }
      break;
    }
  }
}
