import "dart:async";

import "package:moxxyv2/service/service.dart";
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
  
  RosterService() : _log = Logger("RosterService");
  
  Future<bool> isInRoster(String jid) async {
    return await GetIt.I.get<DatabaseService>().isInRoster(jid);
  }

  /// Load the roster from the database. This function is guarded against loading the
  /// roster multiple times and thus creating too many "RosterDiff" actions.
  Future<List<RosterItem>> loadRosterFromDatabase() async {
    return await GetIt.I.get<DatabaseService>().loadRosterItems();
  }

  /// Attempts to add an item to the roster by first performing the roster set
  /// and, if it was successful, create the database entry. Returns the
  /// [RosterItem] model object.
  Future<RosterItem> addToRosterWrapper(String avatarUrl, String jid, String title) async {
    final item = await GetIt.I.get<DatabaseService>().addRosterItemFromData(avatarUrl, jid, title);
    final result = await GetIt.I.get<XmppConnection>().getRosterManager().addToRoster(jid, title);
    if (!result) {
      // TODO: Signal error?
    }

    GetIt.I.get<XmppConnection>().getPresenceManager().sendSubscriptionRequest(jid);

    sendEvent(RosterDiffEvent(added: [ item ]));
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
    final roster = GetIt.I.get<XmppConnection>().getRosterManager();
    final presence = GetIt.I.get<XmppConnection>().getPresenceManager();
    final result = await roster.removeFromRoster(jid);
    if (result == RosterRemovalResult.okay || result == RosterRemovalResult.itemNotFound) {
      if (unsubscribe) {
        presence.sendUnsubscriptionRequest(jid);
      }

      _log.finest("Removing from roster maybe worked. Removing from database");
      await removeFromRosterDatabase(jid, nullOkay: false);
      return true;
    }

    return false;
  }

  Future<void> requestRoster() async {
    final result = await GetIt.I.get<XmppConnection>().getManagerById(rosterManager)!.requestRoster();

    _log.finest("requestRoster: Done");
    
    if (result == null || result.items.isEmpty) {
      _log.fine("requestRoster: No roster items received");
      return;
    }

    final newItems = List<RosterItem>.empty(growable: true);
    final removedItems = List<String>.empty(growable: true);
    final modifiedItems = List<RosterItem>.empty(growable: true);
    final db = GetIt.I.get<DatabaseService>();
    final currentRoster = await db.getRoster();

    // Handle modified and new items
    // TODO: I messed the types up
    for (final item in currentRoster) {
      if (listContains(result.items, (XmppRosterItem i) => i.jid == item.jid)) {
        // TODO: Diff and update if needed
        modifiedItems.add(item);
      } else {
        await db.removeRosterItemByJid(item.jid);
        removedItems.add(item.jid);

        if (await isInRoster(item.jid)) continue;
        newItems.add(await db.addRosterItemFromData(
            "",
            item.jid,
            item.jid.split("@")[0]
        ));
      }
    }

    // Handle deleted items
    for (final item in result.items) {
      if (!listContains(currentRoster, (RosterItem i) => i.jid == item.jid)) {
        if (await isInRoster(item.jid)) continue;
        newItems.add(await db.addRosterItemFromData(
            "",
            item.jid,
            item.jid.split("@")[0]
        ));
      }
    }

    sendEvent(
      RosterDiffEvent(
        added: newItems,
        modified: modifiedItems,
        removed: removedItems
      )
    );
  }

  /// Handles a roster push.
  Future<void> handleRosterPushEvent(RosterPushEvent event) async {
    final item = event.item;


    final db = GetIt.I.get<DatabaseService>();
    final rosterItem = await db.getRosterItemByJid(item.jid);
    final RosterItem modelRosterItem;

    if (item.subscription == "remove") {
      // NOTE: It could be that we triggered this roster push and thus have it already
      //       removed.
      await removeFromRosterDatabase(item.jid, nullOkay: true);

      sendEvent(
        RosterDiffEvent(
          removed: [ item.jid ]
        )
      );

      return;
    }

    // Handle all other cases the same
    if (rosterItem != null) {
      modelRosterItem = await db.updateRosterItem(
        id: rosterItem.id,
        title: item.name,
        groups: item.groups
      );

      sendEvent(
        RosterDiffEvent(
          modified: [ modelRosterItem ]
        )
      );
    } else {
      if (await isInRoster(item.jid)) {
        _log.info("Received roster push for ${item.jid} but this JID is already in the roster database. Ignoring...");
        return;
      }

      modelRosterItem = await db.addRosterItemFromData(
        "",
        item.jid,
        item.jid.split("@")[0],
        groups: item.groups
      );

      sendEvent(
        RosterDiffEvent(
          added: [ modelRosterItem ]
        )
      );
    }
  }
}
