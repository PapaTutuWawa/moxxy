import "dart:async";

import "package:moxxyv2/service/database.dart";
import "package:moxxyv2/shared/models/roster.dart";
import "package:moxxyv2/shared/helpers.dart";
import "package:moxxyv2/shared/events.dart";
import "package:moxxyv2/xmpp/connection.dart";
import "package:moxxyv2/xmpp/managers/namespaces.dart";
import "package:moxxyv2/xmpp/roster.dart";

import "package:get_it/get_it.dart";
import "package:logging/logging.dart";

class RosterService {
  final Logger _log;
  final void Function(BaseIsolateEvent) sendData;
  final List<String> _pendingRequests;
  
  RosterService({ required this.sendData }) : _pendingRequests = List.empty(growable: true), _log = Logger("RosterService");

  /// Returns true if we have a pending request for the jid.
  bool hasPendingRequest(String jid) => _pendingRequests.contains(jid);

  /// Removes a pending request for a jid.
  void removePendingRequest(String jid) => _pendingRequests.remove(jid);
  
  Future<bool> isInRoster(String jid) async {
    return await GetIt.I.get<DatabaseService>().isInRoster(jid);
  }

  /// Load the roster from the database. This function is guarded against loading the
  /// roster multiple times and thus creating too many "RosterDiff" actions.
  Future<void> loadRosterFromDatabase() async {
    final db = GetIt.I.get<DatabaseService>();
    if (!db.isRosterLoaded()) {
      await db.loadRosterItems(notify: true);
    }
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

    final item = await GetIt.I.get<DatabaseService>().addRosterItemFromData(avatarUrl, jid, title);

    sendData(RosterItemAddedEvent(item: item));
    return item;
  }

  /// Removes the [RosterItem] with jid [jid] from the database.
  Future<void> removeFromRosterDatabase(String jid, { bool nullOkay = false }) async {
    await GetIt.I.get<DatabaseService>().removeRosterItemByJid(jid, nullOkay: nullOkay);
  }

  /// Removes the [RosterItem] with jid [jid] from the server-side roster and, if
  /// successful, from the database. If [unsubscribe] is true, then [jid] won't receive
  /// our presence anymore.
  Future<bool> removeFromRosterWrapper(String jid, { bool unsubscribe = true }) async {
    final roster = GetIt.I.get<XmppConnection>().getManagerById(rosterManager)!;
    final result = await roster.removeFromRoster(jid);
    if (result) {
      if (unsubscribe) {
        await roster.sendUnsubscriptionRequest(jid);
      }
    }

    await removeFromRosterDatabase(jid);
    return true;
  }

  Future<void> requestRoster() async {
    final result = await GetIt.I.get<XmppConnection>().getManagerById(rosterManager)!.requestRoster();

    _log.finest("requestRoster: Done");
    
    if (result == null || result.items.isEmpty) {
      _log.fine("requestRoster: No roster items received");
      return;
    }

    // TODO: Figure out if an item was removed
    final newItems = List<RosterItem>.empty(growable: true);
    final removedItems = List<String>.empty(growable: true);
    final modifiedItems = List<RosterItem>.empty(growable: true);
    final db = GetIt.I.get<DatabaseService>();
    final currentRoster = await db.getRoster();

    // Handle modified and new items
    for (final item in currentRoster) {
      if (listContains(result, (RosterItem i) => i.jid == item.jid)) {
        // TODO: Diff and update if needed
        modifiedItems.add(item);
      } else {
        await db.removeRosterItemByJid(item.jid);
        removedItems.add(item.jid);

        newItems.add(await db.addRosterItemFromData(
            "",
            item.jid,
            item.jid.split("@")[0]
        ));
      }
    }

    // Handle deleted items
    for (final item in result) {
      if (!listContains(currentRoster, (RosterItem i) => i.jid == item.jid)) {
        newItems.add(await db.addRosterItemFromData(
            "",
            item.jid,
            item.jid.split("@")[0]
        ));
      }
    }

    // TODO: REMOVE
    final jids = (await db.getRoster()).map((item) => item.jid).toList();
    _log.finest("Current roster: " + jids.toString());
    // TODO END

    sendData(RosterDiffEvent(
        newItems: newItems,
        removedItems: removedItems,
        changedItems: modifiedItems
    ));
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

    final db = GetIt.I.get<DatabaseService>();
    final rosterItem = await db.getRosterItemByJid(item.jid);
    final RosterItem modelRosterItem;

    if (item.subscription == "remove") {
      await removeFromRosterWrapper(item.jid);

      sendData(RosterDiffEvent(
          removedItems: [ item.jid ]
      ));

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

    sendData(RosterDiffEvent(
        changedItems: [ modelRosterItem ]
    ));
  }

  // Handle a [RosterItemNotFoundEvent].
  Future<void> handleRosterItemNotFoundEvent(RosterItemNotFoundEvent event) async {
    switch (event.trigger) {
      case RosterItemNotFoundTrigger.remove: {
        sendData(RosterDiffEvent(
            removedItems: [ event.jid ]
        ));
        await removeFromRosterDatabase(event.jid);
      }
      break;
    }
  }
}
