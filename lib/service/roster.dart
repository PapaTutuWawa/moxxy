import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:moxlib/moxlib.dart';
import 'package:moxplatform/moxplatform.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxyv2/service/contact.dart';
import 'package:moxxyv2/service/conversation.dart';
import 'package:moxxyv2/service/database/database.dart';
import 'package:moxxyv2/service/not_specified.dart';
import 'package:moxxyv2/service/service.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/shared/models/conversation.dart';
import 'package:moxxyv2/shared/models/roster.dart';

/// Closure which returns true if the jid of a [RosterItem] is equal to [jid].
bool Function(RosterItem) _jidEqualsWrapper(String jid) {
  return (i) => i.jid == jid;
}

typedef AddRosterItemFunction = Future<RosterItem> Function(
  String avatarUrl,
  String avatarHash,
  String jid,
  String title,
  String subscription,
  String ask,
  String? contactId,
  {
    List<String> groups,
  }
);
typedef UpdateRosterItemFunction = Future<RosterItem> Function(
  int id, {
    String? avatarUrl,
    String? avatarHash,
    String? title,
    String? subscription,
    String? ask,
    List<String>? groups,
  }
);
typedef RemoveRosterItemFunction = Future<void> Function(String jid);
typedef GetConversationFunction = Future<Conversation?> Function(String jid);
typedef SendEventFunction = void Function(BackgroundEvent event, { String? id });

/// Compare the local roster with the roster we received either by request or by push.
/// Returns a diff between the roster before and after the request or the push.
/// NOTE: This abuses the [RosterDiffEvent] type a bit.
Future<RosterDiffEvent> processRosterDiff(
  List<RosterItem> currentRoster,
  List<XmppRosterItem> remoteRoster,
  bool isRosterPush,
  AddRosterItemFunction addRosterItemFromData,
  UpdateRosterItemFunction updateRosterItem,
  RemoveRosterItemFunction removeRosterItemByJid,
  GetConversationFunction getConversationByJid,
  SendEventFunction _sendEvent,
) async {
  final removed = List<String>.empty(growable: true);
  final modified = List<RosterItem>.empty(growable: true);
  final added = List<RosterItem>.empty(growable: true);

  for (final item in remoteRoster) {
    if (isRosterPush) {
      final litem = firstWhereOrNull(currentRoster, _jidEqualsWrapper(item.jid));
      if (litem != null) {
        if (item.subscription == 'remove') {
          // We have the item locally but it has been removed
          await removeRosterItemByJid(item.jid);
          removed.add(item.jid);
          continue;
        }

        // Item has been modified
        final newItem = await updateRosterItem(
          litem.id,
          subscription: item.subscription,
          title: item.name,
          ask: item.ask,
          groups: item.groups,
        );

        modified.add(newItem);

        // Check if we have a conversation that we need to modify
        final conv = await getConversationByJid(item.jid);
        if (conv != null) {
          _sendEvent(
            ConversationUpdatedEvent(
              conversation: conv.copyWith(subscription: item.subscription),
            ),
          );
        }
      } else {
        // Item does not exist locally
        if (item.subscription == 'remove') {
          // Item has been removed but we don't have it locally
          removed.add(item.jid);
        } else {
          // Item has been added and we don't have it locally
          final newItem = await addRosterItemFromData(
            '',
            '',
            item.jid,
            item.name ?? item.jid.split('@')[0],
            item.subscription,
            item.ask ?? '',
            await GetIt.I.get<ContactsService>().getContactIdForJid(item.jid),
            groups: item.groups,
          );

          added.add(newItem);
        }
      }
    } else {
      final litem = firstWhereOrNull(currentRoster, _jidEqualsWrapper(item.jid));
      if (litem != null) {
        // Item is modified
        if (litem.title != item.name || litem.subscription != item.subscription || !listEquals(litem.groups, item.groups)) {
          final modifiedItem = await updateRosterItem(
            litem.id,
            title: item.name,
            subscription: item.subscription,
            groups: item.groups,
          );
          modified.add(modifiedItem);

          // Check if we have a conversation that we need to modify
          final conv = await getConversationByJid(litem.jid);
          if (conv != null) {
            _sendEvent(
              ConversationUpdatedEvent(
                conversation: conv.copyWith(subscription: item.subscription),
              ),
            );
          }
        }
      } else {
        // Item is new
        added.add(await addRosterItemFromData(
            '',
            '',
            item.jid,
            item.jid.split('@')[0],
            item.subscription,
            item.ask ?? '',
            await GetIt.I.get<ContactsService>().getContactIdForJid(item.jid),
            groups: item.groups,
        ),);
      }
    }
  }

  if (!isRosterPush) {
    for (final item in currentRoster) {
      final ritem = firstWhereOrNull(remoteRoster, (XmppRosterItem i) => i.jid == item.jid);
      if (ritem == null) {
        await removeRosterItemByJid(item.jid);
        removed.add(item.jid);
      }
      // We don't handle the modification case here as that is covered by the huge
      // loop above
    }
  }
  
  return RosterDiffEvent(
    added: added,
    modified: modified,
    removed: removed,
  );
}

class RosterService {
  
  RosterService()
    : _rosterCache = HashMap(),
      _rosterLoaded = false,
      _log = Logger('RosterService');
  final HashMap<String, RosterItem> _rosterCache;
  bool _rosterLoaded;
  final Logger _log;
  
  Future<bool> isInRoster(String jid) async {
    if (!_rosterLoaded) {
      await loadRosterFromDatabase();
    }

    return _rosterCache.containsKey(jid);
  }

  /// Wrapper around [DatabaseService]'s addRosterItemFromData that updates the cache.
  Future<RosterItem> addRosterItemFromData(
    String avatarUrl,
    String avatarHash,
    String jid,
    String title,
    String subscription,
    String ask,
    String? contactId,
    {
      List<String> groups = const [],
    }
  ) async {
    final item = await GetIt.I.get<DatabaseService>().addRosterItemFromData(
      avatarUrl,
      avatarHash,
      jid,
      title,
      subscription,
      ask,
      contactId,
      groups: groups,
    );

    // Update the cache
    _rosterCache[item.jid] = item;

    return item;
  }

  /// Wrapper around [DatabaseService]'s updateRosterItem that updates the cache.
  Future<RosterItem> updateRosterItem(
    int id, {
      String? avatarUrl,
      String? avatarHash,
      String? title,
      String? subscription,
      String? ask,
      List<String>? groups,
      Object? contactId = notSpecified,
    }
  ) async {
    final newItem = await GetIt.I.get<DatabaseService>().updateRosterItem(
      id,
      avatarUrl: avatarUrl,
      avatarHash: avatarHash,
      title: title,
      subscription: subscription,
      ask: ask,
      groups: groups,
      contactId: contactId,
    );

    // Update cache
    _rosterCache[newItem.jid] = newItem;
    
    return newItem;
  }

  /// Wrapper around [DatabaseService]'s removeRosterItem.
  Future<void> removeRosterItem(int id) async {
    await GetIt.I.get<DatabaseService>().removeRosterItem(id);

    /// Update cache
    _rosterCache.removeWhere((_, value) => value.id == id);
  }

  /// Removes a roster item from the database based on its JID.
  Future<void> removeRosterItemByJid(String jid) async {
    if (!_rosterLoaded) {
      await loadRosterFromDatabase();
    }

    for (final item in _rosterCache.values) {
      if (item.jid == jid) {
        await removeRosterItem(item.id);
        return;
      }
    }
  }
  
  /// Returns the entire roster
  Future<List<RosterItem>> getRoster() async {
    if (!_rosterLoaded) {
      await loadRosterFromDatabase();
    }

    return _rosterCache.values.toList();
  }

  /// Returns the roster item with jid [jid] if it exists. Null otherwise.
  Future<RosterItem?> getRosterItemByJid(String jid) async {
    if (await isInRoster(jid)) {
      return _rosterCache[jid];
    }

    return null;
  }
  
  /// Load the roster from the database. This function is guarded against loading the
  /// roster multiple times and thus creating too many "RosterDiff" actions.
  Future<List<RosterItem>> loadRosterFromDatabase() async {
    final items = await GetIt.I.get<DatabaseService>().loadRosterItems();

    _rosterLoaded = true;
    for (final item in items) {
      _rosterCache[item.jid] = item;
    }
    
    return items;
  }
  
  /// Attempts to add an item to the roster by first performing the roster set
  /// and, if it was successful, create the database entry. Returns the
  /// [RosterItem] model object.
  Future<RosterItem> addToRosterWrapper(String avatarUrl, String avatarHash, String jid, String title) async {
    final item = await addRosterItemFromData(
      avatarUrl,
      avatarHash,
      jid,
      title,
      'none',
      '',
      await GetIt.I.get<ContactsService>().getContactIdForJid(jid),
    );
    final result = await GetIt.I.get<XmppConnection>().getRosterManager().addToRoster(jid, title);
    if (!result) {
      // TODO(Unknown): Signal error?
    }
    
    GetIt.I.get<XmppConnection>().getPresenceManager().sendSubscriptionRequest(jid);

    sendEvent(RosterDiffEvent(added: [ item ]));
    return item;
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

      _log.finest('Removing from roster maybe worked. Removing from database');
      await removeRosterItemByJid(jid);
      return true;
    }

    return false;
  }

  Future<void> requestRoster() async {
    final roster = GetIt.I.get<XmppConnection>().getManagerById<RosterManager>(rosterManager)!;
    Result<RosterRequestResult?, RosterError> result;
    if (roster.rosterVersioningAvailable()) {
      _log.fine('Stream supports roster versioning');
      result = await roster.requestRosterPushes();
      _log.fine('Requesting roster pushes done');
    } else {
      _log.fine('Stream does not support roster versioning');
      result = await roster.requestRoster();
    }

    if (result.isType<RosterError>()) {
      _log.warning('Failed to request roster');
      return;
    }

    final value = result.get<RosterRequestResult?>();
    if (value != null) {
      final currentRoster = await getRoster();
      sendEvent(
        await processRosterDiff(
          currentRoster,
          value.items,
          false,
          addRosterItemFromData,
          updateRosterItem,
          removeRosterItemByJid,
          GetIt.I.get<ConversationService>().getConversationByJid,
          sendEvent,
        ),
      );
    }
  }

  /// Handles a roster push.
  Future<void> handleRosterPushEvent(RosterPushEvent event) async {
    final item = event.item;
    final currentRoster = await getRoster();
    sendEvent(
      await processRosterDiff(
        currentRoster,
        [ item ],
        true,
        addRosterItemFromData,
        updateRosterItem,
        removeRosterItemByJid,
        GetIt.I.get<ConversationService>().getConversationByJid,
        sendEvent,
      ),
    );
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
