import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/creation.dart';
import 'package:moxxyv2/service/database/helpers.dart';
import 'package:moxxyv2/service/database/migrations/0000_blocklist.dart';
import 'package:moxxyv2/service/database/migrations/0000_contacts_integration.dart';
import 'package:moxxyv2/service/database/migrations/0000_contacts_integration_avatar.dart';
import 'package:moxxyv2/service/database/migrations/0000_contacts_integration_pseudo.dart';
import 'package:moxxyv2/service/database/migrations/0000_conversations.dart';
import 'package:moxxyv2/service/database/migrations/0000_conversations2.dart';
import 'package:moxxyv2/service/database/migrations/0000_conversations3.dart';
import 'package:moxxyv2/service/database/migrations/0000_language.dart';
import 'package:moxxyv2/service/database/migrations/0000_lmc.dart';
import 'package:moxxyv2/service/database/migrations/0000_omemo_fingerprint_cache.dart';
import 'package:moxxyv2/service/database/migrations/0000_pseudo_messages.dart';
import 'package:moxxyv2/service/database/migrations/0000_reactions.dart';
import 'package:moxxyv2/service/database/migrations/0000_reactions_store_hint.dart';
import 'package:moxxyv2/service/database/migrations/0000_retraction.dart';
import 'package:moxxyv2/service/database/migrations/0000_retraction_conversation.dart';
import 'package:moxxyv2/service/database/migrations/0000_shared_media.dart';
import 'package:moxxyv2/service/database/migrations/0000_stickers.dart';
import 'package:moxxyv2/service/database/migrations/0000_stickers_hash_key.dart';
import 'package:moxxyv2/service/database/migrations/0000_stickers_hash_key2.dart';
import 'package:moxxyv2/service/database/migrations/0000_stickers_missing_attributes.dart';
import 'package:moxxyv2/service/database/migrations/0000_stickers_missing_attributes2.dart';
import 'package:moxxyv2/service/database/migrations/0000_stickers_missing_attributes3.dart';
import 'package:moxxyv2/service/database/migrations/0000_stickers_privacy.dart';
import 'package:moxxyv2/service/database/migrations/0000_xmpp_state.dart';
import 'package:moxxyv2/service/database/migrations/0001_conversation_media_amount.dart';
import 'package:moxxyv2/service/database/migrations/0001_conversation_primary_key.dart';
import 'package:moxxyv2/service/database/migrations/0001_conversations_type.dart';
import 'package:moxxyv2/service/database/migrations/0001_debug_menu.dart';
import 'package:moxxyv2/service/database/migrations/0001_remove_auto_accept_subscriptions.dart';
import 'package:moxxyv2/service/database/migrations/0001_subscriptions.dart';
import 'package:moxxyv2/service/database/migrations/0002_file_metadata_table.dart';
import 'package:moxxyv2/service/database/migrations/0002_shared_media.dart';
import 'package:moxxyv2/service/database/migrations/0002_sticker_metadata.dart';
import 'package:moxxyv2/service/database/migrations/0002_reactions.dart';
import 'package:moxxyv2/service/database/migrations/0002_reactions_2.dart';
import 'package:moxxyv2/service/not_specified.dart';
import 'package:moxxyv2/service/omemo/omemo.dart';
import 'package:moxxyv2/service/omemo/types.dart';
import 'package:moxxyv2/service/roster.dart';
import 'package:moxxyv2/shared/models/conversation.dart';
import 'package:moxxyv2/shared/models/file_metadata.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/shared/models/preferences.dart';
import 'package:moxxyv2/shared/models/roster.dart';
import 'package:moxxyv2/shared/models/xmpp_state.dart';
import 'package:omemo_dart/omemo_dart.dart';
import 'package:path/path.dart' as path;
import 'package:random_string/random_string.dart';
// ignore: implementation_imports
import 'package:sqflite_common/src/sql_builder.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

const databasePasswordKey = 'database_encryption_password';

extension DatabaseHelpers on Database {
  // TODO: Implement whereArgs
  Future<int> count(
    String table,
    String where,
  ) async {
    return Sqflite.firstIntValue(
      await rawQuery(
        'SELECT COUNT(*) FROM $table WHERE $where',
      ),
    )!;
  }

  /// Like update but returns the affected row.
  Future<Map<String, Object?>> updateAndReturn(
    String table,
    Map<String, Object?> values, {
    required String where,
    required List<Object?> whereArgs,
  }) async {
    final q = SqlBuilder.update(
      table,
      values,
      where: where,
      whereArgs: whereArgs,
    );

    final result = await rawQuery(
      '${q.sql} RETURNING *',
      q.arguments,
    );
    assert(result.length == 1, 'Only one row must be returned');
    return result.first;
  }

  /// Like insert but returns the affected row.
  Future<Map<String, Object?>> insertAndReturn(
    String table,
    Map<String, Object?> values,
  ) async {
    final q = SqlBuilder.insert(
      table,
      values,
    );

    final result = await rawQuery(
      '${q.sql} RETURNING *',
      q.arguments,
    );
    assert(result.length == 1, 'Only one row must be returned');
    return result.first;
  }
}

class DatabaseService {
  /// Secure storage for accesing the database encryption key.
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    // TODO(Unknown): Set other options
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// Logger.
  final Logger _log = Logger('DatabaseService');

  /// The database.
  late Database _db;

  /// Public getter for the database
  // TODO(PapaTutuWawa): Remove this getter and just make _db the new database
  Database get database => _db;

  Future<void> initialize() async {
    final dbPath = path.join(
      await getDatabasesPath(),
      'moxxy.db',
    );

    String key;
    if (await _storage.containsKey(key: databasePasswordKey)) {
      _log.finest('Database encryption key found');
      key = (await _storage.read(key: databasePasswordKey))!;
    } else {
      _log.finest('Database encryption not key found. Generating it...');
      key = randomAlphaNumeric(
        40,
        provider: CoreRandomProvider.from(Random.secure()),
      );
      await _storage.write(key: databasePasswordKey, value: key);
      _log.finest('Key generation done...');
    }

    _db = await openDatabase(
      dbPath,
      password: key,
      version: 36,
      onCreate: createDatabase,
      onConfigure: (db) async {
        // In order to do schema changes during database upgrades, we disable foreign
        // keys in the onConfigure phase, but re-enable them here.
        // See https://github.com/tekartik/sqflite/issues/624#issuecomment-813324273
        // for the "solution".
        await db.execute('PRAGMA foreign_keys = OFF');
      },
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          _log.finest('Running migration for database version 2');
          await upgradeFromV1ToV2(db);
        }
        if (oldVersion < 3) {
          _log.finest('Running migration for database version 3');
          await upgradeFromV2ToV3(db);
        }
        if (oldVersion < 4) {
          _log.finest('Running migration for database version 4');
          await upgradeFromV3ToV4(db);
        }
        if (oldVersion < 5) {
          _log.finest('Running migration for database version 5');
          await upgradeFromV4ToV5(db);
        }
        if (oldVersion < 6) {
          _log.finest('Running migration for database version 6');
          await upgradeFromV5ToV6(db);
        }
        if (oldVersion < 7) {
          _log.finest('Running migration for database version 7');
          await upgradeFromV6ToV7(db);
        }
        if (oldVersion < 8) {
          _log.finest('Running migration for database version 8');
          await upgradeFromV7ToV8(db);
        }
        if (oldVersion < 9) {
          _log.finest('Running migration for database version 9');
          await upgradeFromV8ToV9(db);
        }
        if (oldVersion < 10) {
          _log.finest('Running migration for database version 10');
          await upgradeFromV9ToV10(db);
        }
        if (oldVersion < 11) {
          _log.finest('Running migration for database version 11');
          await upgradeFromV10ToV11(db);
        }
        if (oldVersion < 12) {
          _log.finest('Running migration for database version 12');
          await upgradeFromV11ToV12(db);
        }
        if (oldVersion < 13) {
          _log.finest('Running migration for database version 13');
          await upgradeFromV12ToV13(db);
        }
        if (oldVersion < 14) {
          _log.finest('Running migration for database version 14');
          await upgradeFromV13ToV14(db);
        }
        if (oldVersion < 15) {
          _log.finest('Running migration for database version 15');
          await upgradeFromV14ToV15(db);
        }
        if (oldVersion < 16) {
          _log.finest('Running migration for database version 16');
          await upgradeFromV15ToV16(db);
        }
        if (oldVersion < 17) {
          _log.finest('Running migration for database version 17');
          await upgradeFromV16ToV17(db);
        }
        if (oldVersion < 18) {
          _log.finest('Running migration for database version 18');
          await upgradeFromV17ToV18(db);
        }
        if (oldVersion < 19) {
          _log.finest('Running migration for database version 19');
          await upgradeFromV18ToV19(db);
        }
        if (oldVersion < 20) {
          _log.finest('Running migration for database version 20');
          await upgradeFromV19ToV20(db);
        }
        if (oldVersion < 21) {
          _log.finest('Running migration for database version 21');
          await upgradeFromV20ToV21(db);
        }
        if (oldVersion < 22) {
          _log.finest('Running migration for database version 22');
          await upgradeFromV21ToV22(db);
        }
        if (oldVersion < 23) {
          _log.finest('Running migration for database version 23');
          await upgradeFromV22ToV23(db);
        }
        if (oldVersion < 24) {
          _log.finest('Running migration for database version 24');
          await upgradeFromV23ToV24(db);
        }
        if (oldVersion < 25) {
          _log.finest('Running migration for database version 25');
          await upgradeFromV24ToV25(db);
        }
        if (oldVersion < 26) {
          _log.finest('Running migration for database version 26');
          await upgradeFromV25ToV26(db);
        }
        if (oldVersion < 27) {
          _log.finest('Running migration for database version 27');
          await upgradeFromV26ToV27(db);
        }
        if (oldVersion < 28) {
          _log.finest('Running migration for database version 28');
          await upgradeFromV27ToV28(db);
        }
        if (oldVersion < 29) {
          _log.finest('Running migration for database version 29');
          await upgradeFromV28ToV29(db);
        }
        if (oldVersion < 30) {
          _log.finest('Running migration for database version 30');
          await upgradeFromV29ToV30(db);
        }
        if (oldVersion < 31) {
          _log.finest('Running migration for database version 31');
          await upgradeFromV30ToV31(db);
        }
        if (oldVersion < 32) {
          _log.finest('Running migration for database version 32');
          await upgradeFromV31ToV32(db);
        }
        if (oldVersion < 33) {
          _log.finest('Running migration for database version 33');
          await upgradeFromV32ToV33(db);
        }
        if (oldVersion < 34) {
          _log.finest('Running migration for database version 34');
          await upgradeFromV33ToV34(db);
        }
        if (oldVersion < 35) {
          _log.finest('Running migration for database version 35');
          await upgradeFromV34ToV35(db);
        }
        if (oldVersion < 36) {
          _log.finest('Running migration for database version 36');
          await upgradeFromV35ToV36(db);
        }
      },
    );

    _log.finest('Database setup done');
  }

  /// Updates the conversation with JID [jid] inside the database.
  Future<Conversation> updateConversation(
    String jid, {
    int? lastChangeTimestamp,
    Message? lastMessage,
    bool? open,
    int? unreadCounter,
    String? avatarUrl,
    ChatState? chatState,
    bool? muted,
    bool? encrypted,
    Object? contactId = notSpecified,
    Object? contactAvatarPath = notSpecified,
    Object? contactDisplayName = notSpecified,
  }) async {
    final c = <String, dynamic>{};

    if (lastMessage != null) {
      c['lastMessageId'] = lastMessage.id;
    }
    if (lastChangeTimestamp != null) {
      c['lastChangeTimestamp'] = lastChangeTimestamp;
    }
    if (open != null) {
      c['open'] = boolToInt(open);
    }
    if (unreadCounter != null) {
      c['unreadCounter'] = unreadCounter;
    }
    if (avatarUrl != null) {
      c['avatarUrl'] = avatarUrl;
    }
    if (muted != null) {
      c['muted'] = boolToInt(muted);
    }
    if (encrypted != null) {
      c['encrypted'] = boolToInt(encrypted);
    }
    if (contactId != notSpecified) {
      c['contactId'] = contactId as String?;
    }
    if (contactAvatarPath != notSpecified) {
      c['contactAvatarPath'] = contactAvatarPath as String?;
    }
    if (contactDisplayName != notSpecified) {
      c['contactDisplayName'] = contactDisplayName as String?;
    }

    final result = await _db.updateAndReturn(
      conversationsTable,
      c,
      where: 'jid = ?',
      whereArgs: [jid],
    );

    final rosterItem =
        await GetIt.I.get<RosterService>().getRosterItemByJid(jid);
    return Conversation.fromDatabaseJson(
      result,
      rosterItem != null,
      rosterItem?.subscription ?? 'none',
      lastMessage,
    );
  }

  /// Creates a [Conversation] inside the database given the data. This is so that the
  /// [Conversation] object can carry its database id.
  Future<Conversation> addConversationFromData(
    String title,
    Message? lastMessage,
    ConversationType type,
    String avatarUrl,
    String jid,
    int unreadCounter,
    int lastChangeTimestamp,
    bool open,
    bool muted,
    bool encrypted,
    String? contactId,
    String? contactAvatarPath,
    String? contactDisplayName,
  ) async {
    final rosterItem =
        await GetIt.I.get<RosterService>().getRosterItemByJid(jid);
    final conversation = Conversation(
      title,
      lastMessage,
      avatarUrl,
      jid,
      unreadCounter,
      type,
      lastChangeTimestamp,
      open,
      rosterItem != null && !rosterItem.pseudoRosterItem,
      rosterItem?.subscription ?? 'none',
      muted,
      encrypted,
      ChatState.gone,
      contactId: contactId,
      contactAvatarPath: contactAvatarPath,
      contactDisplayName: contactDisplayName,
    );

    await _db.insert(conversationsTable, conversation.toDatabaseJson());
    return conversation;
  }

  /// Loads roster items from the database
  Future<List<RosterItem>> loadRosterItems() async {
    final items = await _db.query(rosterTable);

    return items.map(RosterItem.fromDatabaseJson).toList();
  }

  /// Removes a roster item from the database and cache
  Future<void> removeRosterItem(int id) async {
    await _db.delete(
      rosterTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Create a roster item from data
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
    String? contactDisplayName, {
    List<String> groups = const [],
  }) async {
    // TODO(PapaTutuWawa): Handle groups
    final i = RosterItem(
      -1,
      avatarUrl,
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

    return i.copyWith(
      id: await _db.insert(rosterTable, i.toDatabaseJson()),
    );
  }

  /// Updates the roster item with id [id] inside the database.
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
  }) async {
    final i = <String, dynamic>{};

    if (avatarUrl != null) {
      i['avatarUrl'] = avatarUrl;
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

    final result = await _db.updateAndReturn(
      rosterTable,
      i,
      where: 'id = ?',
      whereArgs: [id],
    );

    return RosterItem.fromDatabaseJson(result);
  }

  Future<PreferencesState> getPreferences() async {
    final preferencesRaw = (await _db.query(preferenceTable)).map((preference) {
      switch (preference['type']! as int) {
        case typeInt:
          return {
            ...preference,
            'value': stringToInt(preference['value']! as String),
          };
        case typeBool:
          return {
            ...preference,
            'value': stringToBool(preference['value']! as String),
          };
        case typeString:
        default:
          return preference;
      }
    }).toList();
    final json = <String, dynamic>{};
    for (final preference in preferencesRaw) {
      json[preference['key']! as String] = preference['value'];
    }

    return PreferencesState.fromJson(json);
  }

  Future<void> savePreferences(PreferencesState state) async {
    final stateJson = state.toJson();
    final preferences = stateJson.keys.map((key) {
      int type;
      String value;
      if (stateJson[key] is int) {
        type = typeInt;
        value = intToString(stateJson[key]! as int);
      } else if (stateJson[key] is bool) {
        type = typeBool;
        value = boolToString(stateJson[key]! as bool);
      } else {
        type = typeString;
        value = stateJson[key]! as String;
      }

      return {
        'key': key,
        'type': type,
        'value': value,
      };
    });

    final batch = _db.batch();

    for (final preference in preferences) {
      batch.update(
        preferenceTable,
        preference,
        where: 'key = ?',
        whereArgs: [preference['key']],
      );
    }

    await batch.commit();
  }

  Future<XmppState> getXmppState() async {
    final json = <String, String?>{};
    for (final row in await _db.query(xmppStateTable)) {
      json[row['key']! as String] = row['value'] as String?;
    }

    return XmppState.fromDatabaseTuples(json);
  }

  Future<void> saveXmppState(XmppState state) async {
    final batch = _db.batch();

    for (final tuple in state.toDatabaseTuples().entries) {
      batch.insert(
        xmppStateTable,
        <String, String?>{'key': tuple.key, 'value': tuple.value},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit();
  }

  Future<void> saveRatchet(OmemoDoubleRatchetWrapper ratchet) async {
    final json = await ratchet.ratchet.toJson();
    await _db.insert(
      omemoRatchetsTable,
      {
        ...json,
        'mkskipped': jsonEncode(json['mkskipped']),
        'acknowledged': boolToInt(json['acknowledged']! as bool),
        'jid': ratchet.jid,
        'id': ratchet.id,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<OmemoDoubleRatchetWrapper>> loadRatchets() async {
    final results = await _db.query(omemoRatchetsTable);

    return results.map((ratchet) {
      final json = jsonDecode(ratchet['mkskipped']! as String) as List<dynamic>;
      final mkskipped = List<Map<String, dynamic>>.empty(growable: true);
      for (final i in json) {
        final element = i as Map<String, dynamic>;
        mkskipped.add({
          'key': element['key']! as String,
          'public': element['public']! as String,
          'n': element['n']! as int,
        });
      }

      return OmemoDoubleRatchetWrapper(
        OmemoDoubleRatchet.fromJson(
          {
            ...ratchet,
            'acknowledged': intToBool(ratchet['acknowledged']! as int),
            'mkskipped': mkskipped,
          },
        ),
        ratchet['id']! as int,
        ratchet['jid']! as String,
      );
    }).toList();
  }

  Future<Map<RatchetMapKey, BTBVTrustState>> loadTrustCache() async {
    final entries = await _db.query(omemoTrustCacheTable);

    final mapEntries =
        entries.map<MapEntry<RatchetMapKey, BTBVTrustState>>((entry) {
      // TODO(PapaTutuWawa): Expose this from omemo_dart
      BTBVTrustState state;
      final value = entry['trust']! as int;
      if (value == 1) {
        state = BTBVTrustState.notTrusted;
      } else if (value == 2) {
        state = BTBVTrustState.blindTrust;
      } else if (value == 3) {
        state = BTBVTrustState.verified;
      } else {
        state = BTBVTrustState.notTrusted;
      }

      return MapEntry(
        RatchetMapKey.fromJsonKey(entry['key']! as String),
        state,
      );
    });

    return Map.fromEntries(mapEntries);
  }

  Future<void> saveTrustCache(Map<String, int> cache) async {
    final batch = _db.batch();

    // ignore: cascade_invocations
    batch.delete(omemoTrustCacheTable);
    for (final entry in cache.entries) {
      batch.insert(
        omemoTrustCacheTable,
        {
          'key': entry.key,
          'trust': entry.value,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit();
  }

  Future<Map<RatchetMapKey, bool>> loadTrustEnablementList() async {
    final entries = await _db.query(omemoTrustEnableListTable);

    final mapEntries = entries.map<MapEntry<RatchetMapKey, bool>>((entry) {
      return MapEntry(
        RatchetMapKey.fromJsonKey(entry['key']! as String),
        intToBool(entry['enabled']! as int),
      );
    });

    return Map.fromEntries(mapEntries);
  }

  Future<void> saveTrustEnablementList(Map<String, bool> list) async {
    final batch = _db.batch();

    // ignore: cascade_invocations
    batch.delete(omemoTrustEnableListTable);
    for (final entry in list.entries) {
      batch.insert(
        omemoTrustEnableListTable,
        {
          'key': entry.key,
          'enabled': boolToInt(entry.value),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit();
  }

  Future<Map<String, List<int>>> loadTrustDeviceList() async {
    final entries = await _db.query(omemoTrustDeviceListTable);

    final map = <String, List<int>>{};
    for (final entry in entries) {
      final key = entry['jid']! as String;
      final device = entry['device']! as int;

      if (map.containsKey(key)) {
        map[key]!.add(device);
      } else {
        map[key] = [device];
      }
    }

    return map;
  }

  Future<void> saveTrustDeviceList(Map<String, List<int>> list) async {
    final batch = _db.batch();

    // ignore: cascade_invocations
    batch.delete(omemoTrustDeviceListTable);
    for (final entry in list.entries) {
      for (final device in entry.value) {
        batch.insert(
          omemoTrustDeviceListTable,
          {
            'jid': entry.key,
            'device': device,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }

    await batch.commit();
  }

  Future<void> saveOmemoDevice(OmemoDevice device) async {
    await _db.insert(
      omemoDeviceTable,
      {
        'jid': device.jid,
        'id': device.id,
        'data': jsonEncode(await device.toJson()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<OmemoDevice?> loadOmemoDevice(String jid) async {
    final data = await _db.query(
      omemoDeviceTable,
      where: 'jid = ?',
      whereArgs: [jid],
      limit: 1,
    );
    if (data.isEmpty) return null;

    final deviceJson =
        jsonDecode(data.first['data']! as String) as Map<String, dynamic>;
    // NOTE: We need to do this because Dart otherwise complains about not being able
    //       to cast dynamic to List<int>.
    final opks = List<Map<String, dynamic>>.empty(growable: true);
    final opksIter = deviceJson['opks']! as List<dynamic>;
    for (final tmpOpk in opksIter) {
      final opk = tmpOpk as Map<String, dynamic>;
      opks.add(<String, dynamic>{
        'id': opk['id']! as int,
        'public': opk['public']! as String,
        'private': opk['private']! as String,
      });
    }
    deviceJson['opks'] = opks;
    return OmemoDevice.fromJson(deviceJson);
  }

  Future<Map<String, List<int>>> loadOmemoDeviceList() async {
    final list = await _db.query(omemoDeviceListTable);
    final map = <String, List<int>>{};
    for (final entry in list) {
      final key = entry['jid']! as String;
      final id = entry['id']! as int;

      if (map.containsKey(key)) {
        map[key]!.add(id);
      } else {
        map[key] = [id];
      }
    }

    return map;
  }

  Future<void> saveOmemoDeviceList(Map<String, List<int>> list) async {
    final batch = _db.batch();

    // ignore: cascade_invocations
    batch.delete(omemoDeviceListTable);
    for (final entry in list.entries) {
      for (final id in entry.value) {
        batch.insert(
          omemoDeviceListTable,
          {
            'jid': entry.key,
            'id': id,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }

    await batch.commit();
  }

  Future<void> emptyOmemoSessionTables() async {
    final batch = _db.batch();

    // ignore: cascade_invocations
    batch
      ..delete(omemoRatchetsTable)
      ..delete(omemoTrustCacheTable)
      ..delete(omemoTrustEnableListTable);

    await batch.commit();
  }

  Future<void> addFingerprintsToCache(List<OmemoCacheTriple> items) async {
    final batch = _db.batch();
    for (final item in items) {
      batch.insert(
        omemoFingerprintCache,
        <String, dynamic>{
          'jid': item.jid,
          'id': item.deviceId,
          'fingerprint': item.fingerprint,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit();
  }

  Future<List<OmemoCacheTriple>> getFingerprintsFromCache(String jid) async {
    final rawItems = await _db.query(
      omemoFingerprintCache,
      where: 'jid = ?',
      whereArgs: [jid],
    );

    return rawItems.map((item) {
      return OmemoCacheTriple(
        jid,
        item['id']! as int,
        item['fingerprint']! as String,
      );
    }).toList();
  }

  Future<Map<String, String>> getContactIds() async {
    return Map<String, String>.fromEntries(
      (await _db.query(contactsTable)).map(
        (item) => MapEntry(
          item['jid']! as String,
          item['id']! as String,
        ),
      ),
    );
  }

  Future<void> addContactId(String id, String jid) async {
    await _db.insert(
      contactsTable,
      <String, String>{
        'id': id,
        'jid': jid,
      },
    );
  }

  Future<void> removeContactId(String id) async {
    await _db.delete(
      contactsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> addBlocklistEntry(String jid) async {
    await _db.insert(
      blocklistTable,
      {
        'jid': jid,
      },
    );
  }

  Future<void> removeBlocklistEntry(String jid) async {
    await _db.delete(
      blocklistTable,
      where: 'jid = ?',
      whereArgs: [jid],
    );
  }

  Future<void> removeAllBlocklistEntries() async {
    await _db.delete(
      blocklistTable,
    );
  }

  Future<List<String>> getBlocklistEntries() async {
    final result = await _db.query(blocklistTable);

    return result.map((m) => m['jid']! as String).toList();
  }

  Future<List<String>> getSubscriptionRequests() async {
    return (await _db.query(subscriptionsTable))
        .map((m) => m['jid']! as String)
        .toList();
  }

  Future<void> addSubscriptionRequest(String jid) async {
    await _db.insert(
      subscriptionsTable,
      {
        'jid': jid,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> removeSubscriptionRequest(String jid) async {
    await _db.delete(
      subscriptionsTable,
      where: 'jid = ?',
      whereArgs: [jid],
    );
  }

  Future<FileMetadata> addFileMetadataFromData(
    FileMetadata metadata,
  ) async {
    final result = await _db.insertAndReturn(
      fileMetadataTable,
      metadata.toDatabaseJson(),
    );
    return FileMetadata.fromDatabaseJson(result);
  }
}
