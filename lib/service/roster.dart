import "dart:async";

import "package:moxxyv2/service/service.dart";
import "package:moxxyv2/service/database.dart";
import "package:moxxyv2/service/conversation.dart";
import "package:moxxyv2/shared/models/roster.dart";
import "package:moxxyv2/shared/helpers.dart";
import "package:moxxyv2/shared/events.dart";
import "package:moxxyv2/xmpp/connection.dart";
import "package:moxxyv2/xmpp/managers/namespaces.dart";
import "package:moxxyv2/xmpp/roster.dart";

import "package:get_it/get_it.dart";
import "package:logging/logging.dart";

/// Closure which returns true if the jid of a [RosterItem] is equal to [jid].
bool Function(RosterItem) _jidEqualsWrapper(String jid) {
  return (i) => i.jid == jid;
}

/// Compare the local roster with the roster we received either by request or by push.
/// Returns a diff between the roster before and after the request or the push.
/// NOTE: This abuses the [RosterDiffEvent] type a bit.
Future<RosterDiffEvent> rosterDiff(List<RosterItem> currentRoster, List<XmppRosterItem> remoteRoster, bool isRosterPush) async {
  final List<String> removed = List.empty(growable: true);
  final List<RosterItem> modified = List.empty(growable: true);
  final List<RosterItem> added = List.empty(growable: true);
  final db = GetIt.I.get<DatabaseService>();
  final cs = GetIt.I.get<ConversationService>();

  for (final item in remoteRoster) {
    if (isRosterPush) {
      // Handle removed items
      if (item.subscription == "remove") {
        removed.add(item.jid);
        continue;
      }

      final litem = firstWhereOrNull(currentRoster, _jidEqualsWrapper(item.jid));
      if (litem != null) {
        // Item has been modified
        final newItem = await db.updateRosterItem(
          id: litem.id,
          subscription: item.subscription,
          groups: item.groups
        );

        modified.add(newItem);

        // Check if we have a conversation that we need to modify
        final conv = await cs.getConversationByJid(item.jid);
        if (conv != null) {
          sendEvent(
            ConversationUpdatedEvent(
              conversation: conv.copyWith(subscription: item.subscription)
            )
          );
        }
      } else {
        // Item has been modified
        final newItem = await db.addRosterItemFromData(
          "",
          item.jid,
          item.name ?? item.jid.split("@")[0],
          item.subscription,
          item.ask ?? "",
          groups: item.groups
        );

        added.add(newItem);
      }
    } else {
      if (!listContains(currentRoster, (RosterItem i) => i.jid == item.jid)) {
        // Item has been deleted
        removed.add(item.jid);
        continue;
      }

      final litem = firstWhereOrNull(currentRoster, _jidEqualsWrapper(item.jid));
      if (litem != null) {
        // Item is modified
        if (litem.title != item.name || litem.subscription != item.subscription || litem.groups != item.groups) {
          final modifiedItem = await db.updateRosterItem(
            id: litem.id,
            title: item.name,
            subscription: item.subscription,
            groups: item.groups
          );
          modified.add(modifiedItem);

          // Check if we have a conversation that we need to modify
          final conv = await cs.getConversationByJid(litem.jid);
          if (conv != null) {
            sendEvent(
              ConversationUpdatedEvent(
                conversation: conv.copyWith(subscription: item.subscription)
              )
            );
          }
        }
      } else {
        // Item is new
        added.add(await db.addRosterItemFromData(
            "",
            item.jid,
            item.jid.split("@")[0],
            item.subscription,
            item.ask ?? "",
            groups: item.groups
        ));
      }
    }
  }
  
  return RosterDiffEvent(
    added: added,
    modified: modified,
    removed: removed
  );
}

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
    final item = await GetIt.I.get<DatabaseService>().addRosterItemFromData(
      avatarUrl,
      jid,
      title,
      "none",
      ""
    );
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

    final currentRoster = await GetIt.I.get<DatabaseService>().getRoster();
    sendEvent(await rosterDiff(currentRoster, result.items, false));
  }

  /// Handles a roster push.
  Future<void> handleRosterPushEvent(RosterPushEvent event) async {
    final item = event.item;
    final currentRoster = await GetIt.I.get<DatabaseService>().getRoster();
    sendEvent(await rosterDiff(currentRoster, [ item ], true));
  }

  Future<void> acceptSubscriptionRequest(String jid) async {
    GetIt.I.get<XmppConnection>().getPresenceManager().sendSubscriptionRequestApproval(jid);
  }

  Future<void> rejectSubscriptionRequest(String jid) async {
    GetIt.I.get<XmppConnection>().getPresenceManager().sendSubscriptionRequestRejection(jid);
  }

  void sendSubscriptionRequest(String jid) {
    GetIt.I.get<XmppConnection>().getPresenceManager().sendSubscriptionRequest(jid);
  }
  
  void sendUnsubscriptionRequest(String jid) {
    GetIt.I.get<XmppConnection>().getPresenceManager().sendUnsubscriptionRequest(jid);
  }
}
