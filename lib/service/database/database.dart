import 'dart:async';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';
import 'package:moxxyv2/service/database/creation.dart';
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
import 'package:moxxyv2/service/database/migrations/0002_indices.dart';
import 'package:moxxyv2/service/database/migrations/0002_reactions.dart';
import 'package:moxxyv2/service/database/migrations/0002_reactions_2.dart';
import 'package:moxxyv2/service/database/migrations/0002_shared_media.dart';
import 'package:moxxyv2/service/database/migrations/0002_sticker_metadata.dart';
import 'package:path/path.dart' as path;
import 'package:random_string/random_string.dart';
// ignore: implementation_imports
import 'package:sqflite_common/src/sql_builder.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

const databasePasswordKey = 'database_encryption_password';

extension DatabaseHelpers on Database {
  /// Count the number of rows in [table] where [where] with the arguments [whereArgs]
  /// matches.
  Future<int> count(
    String table,
    String where,
    List<Object?> whereArgs,
  ) async {
    return Sqflite.firstIntValue(
      await rawQuery(
        'SELECT COUNT(*) FROM $table WHERE $where',
        whereArgs,
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
      version: 37,
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
        if (oldVersion < 37) {
          _log.finest('Running migration for database version 37');
          await upgradeFromV36ToV37(db);
        }
      },
    );

    _log.finest('Database setup done');
  }
}
