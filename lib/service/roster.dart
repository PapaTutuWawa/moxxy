import 'dart:async';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxyv2/service/contacts.dart';
import 'package:moxxyv2/service/database/database.dart';
import 'package:moxxyv2/service/not_specified.dart';
import 'package:moxxyv2/service/service.dart';
import 'package:moxxyv2/service/subscription.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/shared/models/roster.dart';

class RosterService {
  /// The cached list of JID -> RosterItem. Null if not yet loaded
  Map<String, RosterItem>? _rosterCache;

  /// Logger.
  final Logger _log = Logger('RosterService');

  Future<void> _loadRosterIfNeeded() async {
    if (_rosterCache == null) {
      await loadRosterFromDatabase();
    }
  }

  Future<bool> isInRoster(String jid) async {
    await _loadRosterIfNeeded();
    return _rosterCache!.containsKey(jid);
  }

  /// Wrapper around [DatabaseService]'s addRosterItemFromData that updates the cache.
  Future<RosterItem> addRosterItemFromData(
    String avatarUrl,
    String avatarHash,
    String jid,
    String title,
    String subscription,
    String ask,
    bool pseudoRosterItem,
    String? contactId,
    String? contactAvatarPath,
    String? contactDisplayName,
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
      pseudoRosterItem,
      contactId,
      contactAvatarPath,
      contactDisplayName,
      groups: groups,
    );

    // Update the cache
    _rosterCache![item.jid] = item;

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
      Object pseudoRosterItem = notSpecified,
      List<String>? groups,
      Object? contactId = notSpecified,
      Object? contactAvatarPath = notSpecified,
      Object? contactDisplayName = notSpecified,
    }
  ) async {
    final newItem = await GetIt.I.get<DatabaseService>().updateRosterItem(
      id,
      avatarUrl: avatarUrl,
      avatarHash: avatarHash,
      title: title,
      subscription: subscription,
      ask: ask,
      pseudoRosterItem: pseudoRosterItem,
      groups: groups,
      contactId: contactId,
      contactAvatarPath: contactAvatarPath,
      contactDisplayName: contactDisplayName,
    );

    // Update cache
    _rosterCache![newItem.jid] = newItem;
    
    return newItem;
  }

  /// Wrapper around [DatabaseService]'s removeRosterItem.
  Future<void> removeRosterItem(int id) async {
    // NOTE: This call ensures that _rosterCache != null
    await GetIt.I.get<DatabaseService>().removeRosterItem(id);
    assert(_rosterCache != null, '_rosterCache must be non-null');
    
    /// Update cache
    _rosterCache!.removeWhere((_, value) => value.id == id);
  }

  /// Removes a roster item from the database based on its JID.
  Future<void> removeRosterItemByJid(String jid) async {
    await _loadRosterIfNeeded();

    for (final item in _rosterCache!.values) {
      if (item.jid == jid) {
        await removeRosterItem(item.id);
        return;
      }
    }
  }
  
  /// Returns the entire roster
  Future<List<RosterItem>> getRoster() async {
    await _loadRosterIfNeeded();
    return _rosterCache!.values.toList();
  }

  /// Returns the roster item with jid [jid] if it exists. Null otherwise.
  Future<RosterItem?> getRosterItemByJid(String jid) async {
    if (await isInRoster(jid)) {
      return _rosterCache![jid];
    }

    return null;
  }
  
  /// Load the roster from the database. This function is guarded against loading the
  /// roster multiple times and thus creating too many "RosterDiff" actions.
  Future<List<RosterItem>> loadRosterFromDatabase() async {
    final items = await GetIt.I.get<DatabaseService>().loadRosterItems();

    _rosterCache = <String, RosterItem>{};
    for (final item in items) {
      _rosterCache![item.jid] = item;
    }
    
    return items;
  }
  
  /// Attempts to add an item to the roster by first performing the roster set
  /// and, if it was successful, create the database entry. Returns the
  /// [RosterItem] model object.
  Future<RosterItem> addToRosterWrapper(String avatarUrl, String avatarHash, String jid, String title) async {
    final css = GetIt.I.get<ContactsService>();
    final contactId = await css.getContactIdForJid(jid);
    final item = await addRosterItemFromData(
      avatarUrl,
      avatarHash,
      jid,
      title,
      'none',
      '',
      false,
      contactId,
      await css.getProfilePicturePathForJid(jid),
      await css.getContactDisplayName(contactId),
    );
    final result = await GetIt.I.get<XmppConnection>().getRosterManager().addToRoster(jid, title);
    if (!result) {
      // TODO(Unknown): Signal error?
    }

    GetIt.I.get<SubscriptionRequestService>().sendSubscriptionRequest(jid);

    sendEvent(RosterDiffEvent(added: [ item ]));
    return item;
  }

  /// Removes the [RosterItem] with jid [jid] from the server-side roster and, if
  /// successful, from the database. If [unsubscribe] is true, then [jid] won't receive
  /// our presence anymore.
  Future<bool> removeFromRosterWrapper(String jid, { bool unsubscribe = true }) async {
    final roster = GetIt.I.get<XmppConnection>().getRosterManager();
    final result = await roster.removeFromRoster(jid);
    if (result == RosterRemovalResult.okay || result == RosterRemovalResult.itemNotFound) {
      if (unsubscribe) {
        GetIt.I.get<SubscriptionRequestService>().sendUnsubscriptionRequest(jid);
      }

      _log.finest('Removing from roster maybe worked. Removing from database');
      await removeRosterItemByJid(jid);
      return true;
    }

    return false;
  }
}
