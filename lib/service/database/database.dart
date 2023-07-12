import 'dart:async';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logging/logging.dart';
import 'package:meta/meta.dart';
import 'package:moxxyv2/service/database/creation.dart';
import 'package:moxxyv2/service/database/migration.dart';
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
import 'package:moxxyv2/service/database/migrations/0003_avatar_hashes.dart';
import 'package:moxxyv2/service/database/migrations/0003_groupchat_table.dart';
import 'package:moxxyv2/service/database/migrations/0003_new_omemo.dart';
import 'package:moxxyv2/service/database/migrations/0003_new_omemo_pseudo_messages.dart';
import 'package:moxxyv2/service/database/migrations/0003_remove_subscriptions.dart';
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

@internal
const List<DatabaseMigration<Database>> migrations = [
  DatabaseMigration(2, upgradeFromV1ToV2),
  DatabaseMigration(3, upgradeFromV2ToV3),
  DatabaseMigration(4, upgradeFromV3ToV4),
  DatabaseMigration(5, upgradeFromV4ToV5),
  DatabaseMigration(6, upgradeFromV5ToV6),
  DatabaseMigration(7, upgradeFromV6ToV7),
  DatabaseMigration(8, upgradeFromV7ToV8),
  DatabaseMigration(9, upgradeFromV8ToV9),
  DatabaseMigration(10, upgradeFromV9ToV10),
  DatabaseMigration(11, upgradeFromV10ToV11),
  DatabaseMigration(12, upgradeFromV11ToV12),
  DatabaseMigration(13, upgradeFromV12ToV13),
  DatabaseMigration(14, upgradeFromV13ToV14),
  DatabaseMigration(15, upgradeFromV14ToV15),
  DatabaseMigration(16, upgradeFromV15ToV16),
  DatabaseMigration(17, upgradeFromV16ToV17),
  DatabaseMigration(18, upgradeFromV17ToV18),
  DatabaseMigration(19, upgradeFromV18ToV19),
  DatabaseMigration(20, upgradeFromV19ToV20),
  DatabaseMigration(21, upgradeFromV20ToV21),
  DatabaseMigration(22, upgradeFromV21ToV22),
  DatabaseMigration(23, upgradeFromV22ToV23),
  DatabaseMigration(24, upgradeFromV23ToV24),
  DatabaseMigration(25, upgradeFromV24ToV25),
  DatabaseMigration(26, upgradeFromV25ToV26),
  DatabaseMigration(27, upgradeFromV26ToV27),
  DatabaseMigration(28, upgradeFromV27ToV28),
  DatabaseMigration(29, upgradeFromV28ToV29),
  DatabaseMigration(30, upgradeFromV29ToV30),
  DatabaseMigration(31, upgradeFromV30ToV31),
  DatabaseMigration(32, upgradeFromV31ToV32),
  DatabaseMigration(33, upgradeFromV32ToV33),
  DatabaseMigration(34, upgradeFromV33ToV34),
  DatabaseMigration(35, upgradeFromV34ToV35),
  DatabaseMigration(36, upgradeFromV35ToV36),
  DatabaseMigration(37, upgradeFromV36ToV37),
  DatabaseMigration(38, upgradeFromV37ToV38),
  DatabaseMigration(39, upgradeFromV38ToV39),
  DatabaseMigration(40, upgradeFromV39ToV40),
  DatabaseMigration(41, upgradeFromV40ToV41),
  DatabaseMigration(42, upgradeFromV41ToV42),
];

class DatabaseService {
  /// Secure storage for accesing the database encryption key.
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    // TODO(Unknown): Set other options
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// Logger.
  final Logger _log = Logger('DatabaseService');

  /// The database.
  late Database database;

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

    // Just some sanity checks
    final version = migrations.last.version;
    assert(
      migrations.every((migration) => migration.version <= version),
      "Every migration's version must be smaller or equal to the last version",
    );
    assert(
      migrations
          .sublist(0, migrations.length - 1)
          .every((migration) => migration.version < version),
      'The last migration must have the largest version',
    );

    database = await openDatabase(
      dbPath,
      password: key,
      version: version,
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
        await runMigrations(_log, db, migrations, oldVersion);
      },
    );

    _log.finest('Database setup done');
  }
}
