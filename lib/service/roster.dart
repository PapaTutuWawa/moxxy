import 'dart:async';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxyv2/service/contacts.dart';
import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/database.dart';
import 'package:moxxyv2/service/database/helpers.dart';
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
    String avatarPath,
    String avatarHash,
    String jid,
    String title,
    String subscription,
    String ask,
    bool pseudoRosterItem,
    String? contactId,
    String? contactAvatarPath,
    String? contactDisplayName, {
    List<String> groups = const [],
  }) async {
    // TODO(PapaTutuWawa): Handle groups
    final i = RosterItem(
      -1,
      avatarPath,
      avatarHash,
      jid,
      title,
      subscription,
      ask,
      pseudoRosterItem,
      <String>[],
      contactId: contactId,
      contactAvatarPath: contactAvatarPath,
      contactDisplayName: contactDisplayName,
    );

    final item = i.copyWith(
      id: await GetIt.I
          .get<DatabaseService>()
          .database
          .insert(rosterTable, i.toDatabaseJson()),
    );

    // Update the cache
    _rosterCache![item.jid] = item;

    return item;
  }

  /// Wrapper around [DatabaseService]'s updateRosterItem that updates the cache.
  Future<RosterItem> updateRosterItem(
    int id, {
    String? avatarPath,
    String? avatarHash,
    String? title,
    String? subscription,
    String? ask,
    Object pseudoRosterItem = notSpecified,
    List<String>? groups,
    Object? contactId = notSpecified,
    Object? contactAvatarPath = notSpecified,
    Object? contactDisplayName = notSpecified,
  }) async {
    final i = <String, dynamic>{};

    if (avatarPath != null) {
      i['avatarPath'] = avatarPath;
    }
    if (avatarHash != null) {
      i['avatarHash'] = avatarHash;
    }
    if (title != null) {
      i['title'] = title;
    }
    /*
    if (groups != null) {
      i.groups = groups;
    }
    */
    if (subscription != null) {
      i['subscription'] = subscription;
    }
    if (ask != null) {
      i['ask'] = ask;
    }
    if (contactId != notSpecified) {
      i['contactId'] = contactId as String?;
    }
    if (contactAvatarPath != notSpecified) {
      i['contactAvatarPath'] = contactAvatarPath as String?;
    }
    if (contactDisplayName != notSpecified) {
      i['contactDisplayName'] = contactDisplayName as String?;
    }
    if (pseudoRosterItem != notSpecified) {
      i['pseudoRosterItem'] = boolToInt(pseudoRosterItem as bool);
    }

    final result =
        await GetIt.I.get<DatabaseService>().database.updateAndReturn(
      rosterTable,
      i,
      where: 'id = ?',
      whereArgs: [id],
    );
    final newItem = RosterItem.fromDatabaseJson(result);

    // Update cache
    _rosterCache![newItem.jid] = newItem;

    return newItem;
  }

  /// Removes a roster item from the database and cache
  Future<void> removeRosterItem(int id) async {
    // NOTE: This call ensures that _rosterCache != null
    await GetIt.I.get<DatabaseService>().database.delete(
      rosterTable,
      where: 'id = ?',
      whereArgs: [id],
    );
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
    final itemsRaw =
        await GetIt.I.get<DatabaseService>().database.query(rosterTable);
    final items = itemsRaw.map(RosterItem.fromDatabaseJson);

    _rosterCache = <String, RosterItem>{};
    for (final item in items) {
      _rosterCache![item.jid] = item;
    }

    return items.toList();
  }

  /// Attempts to add an item to the roster by first performing the roster set
  /// and, if it was successful, create the database entry. Returns the
  /// [RosterItem] model object.
  Future<RosterItem> addToRosterWrapper(
    String avatarPath,
    String avatarHash,
    String jid,
    String title,
  ) async {
    final css = GetIt.I.get<ContactsService>();
    final contactId = await css.getContactIdForJid(jid);
    final item = await addRosterItemFromData(
      avatarPath,
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

    final conn = GetIt.I.get<XmppConnection>();
    final result = await conn 
        .getRosterManager()!
        .addToRoster(jid, title);
    if (!result) {
      // TODO(Unknown): Signal error?
    }

    final to = JID.fromString(jid);
    final preApproval = await conn.getPresenceManager()!.preApproveSubscription(to);
    if (!preApproval) {
      await conn.getPresenceManager()!.requestSubscription(to);
    }

    sendEvent(RosterDiffEvent(added: [item]));
    return item;
  }

  /// Removes the [RosterItem] with jid [jid] from the server-side roster and, if
  /// successful, from the database. If [unsubscribe] is true, then [jid] won't receive
  /// our presence anymore.
  Future<bool> removeFromRosterWrapper(
    String jid, {
    bool unsubscribe = true,
  }) async {
    final roster = GetIt.I.get<XmppConnection>().getRosterManager()!;
    final result = await roster.removeFromRoster(jid);
    if (result == RosterRemovalResult.okay ||
        result == RosterRemovalResult.itemNotFound) {
      if (unsubscribe) {
        GetIt.I
            .get<SubscriptionRequestService>()
            .sendUnsubscriptionRequest(jid);
      }

      _log.finest('Removing from roster maybe worked. Removing from database');
      await removeRosterItemByJid(jid);
      return true;
    }

    return false;
  }
}
