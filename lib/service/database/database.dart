import 'dart:async';

import 'package:get_it/get_it.dart';
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
import 'package:moxxyv2/service/database/migrations/0003_file_transfer_error_to_warning.dart';
import 'package:moxxyv2/service/database/migrations/0003_groupchat_table.dart';
import 'package:moxxyv2/service/database/migrations/0003_jid_attribute.dart';
import 'package:moxxyv2/service/database/migrations/0003_new_omemo.dart';
import 'package:moxxyv2/service/database/migrations/0003_new_omemo_pseudo_messages.dart';
import 'package:moxxyv2/service/database/migrations/0003_notifications.dart';
import 'package:moxxyv2/service/database/migrations/0003_occupant_id.dart';
import 'package:moxxyv2/service/database/migrations/0003_remove_subscriptions.dart';
import 'package:moxxyv2/service/database/migrations/0003_sticker_pack_timestamp.dart';
import 'package:moxxyv2/service/database/migrations/0004_favourites.dart';
import 'package:moxxyv2/service/database/migrations/0004_groupchat_members.dart';
import 'package:moxxyv2/service/database/migrations/0004_new_avatar_cache.dart';
import 'package:moxxyv2/service/xmpp_state.dart';
import 'package:path/path.dart' as path;
// ignore: implementation_imports
import 'package:sqflite_common/src/sql_builder.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

/// Data passed to the migrations.
typedef DatabaseMigrationData = (Database, Logger);

@internal
const List<Migration<DatabaseMigrationData>> migrations = [
  Migration(2, upgradeFromV1ToV2),
  Migration(3, upgradeFromV2ToV3),
  Migration(4, upgradeFromV3ToV4),
  Migration(5, upgradeFromV4ToV5),
  Migration(6, upgradeFromV5ToV6),
  Migration(7, upgradeFromV6ToV7),
  Migration(8, upgradeFromV7ToV8),
  Migration(9, upgradeFromV8ToV9),
  Migration(10, upgradeFromV9ToV10),
  Migration(11, upgradeFromV10ToV11),
  Migration(12, upgradeFromV11ToV12),
  Migration(13, upgradeFromV12ToV13),
  Migration(14, upgradeFromV13ToV14),
  Migration(15, upgradeFromV14ToV15),
  Migration(16, upgradeFromV15ToV16),
  Migration(17, upgradeFromV16ToV17),
  Migration(18, upgradeFromV17ToV18),
  Migration(19, upgradeFromV18ToV19),
  Migration(20, upgradeFromV19ToV20),
  Migration(21, upgradeFromV20ToV21),
  Migration(22, upgradeFromV21ToV22),
  Migration(23, upgradeFromV22ToV23),
  Migration(24, upgradeFromV23ToV24),
  Migration(25, upgradeFromV24ToV25),
  Migration(26, upgradeFromV25ToV26),
  Migration(27, upgradeFromV26ToV27),
  Migration(28, upgradeFromV27ToV28),
  Migration(29, upgradeFromV28ToV29),
  Migration(30, upgradeFromV29ToV30),
  Migration(31, upgradeFromV30ToV31),
  Migration(32, upgradeFromV31ToV32),
  Migration(33, upgradeFromV32ToV33),
  Migration(34, upgradeFromV33ToV34),
  Migration(35, upgradeFromV34ToV35),
  Migration(36, upgradeFromV35ToV36),
  Migration(37, upgradeFromV36ToV37),
  Migration(38, upgradeFromV37ToV38),
  Migration(39, upgradeFromV38ToV39),
  Migration(40, upgradeFromV39ToV40),
  Migration(41, upgradeFromV40ToV41),
  Migration(42, upgradeFromV41ToV42),
  Migration(43, upgradeFromV42ToV43),
  Migration(44, upgradeFromV43ToV44),
  Migration(45, upgradeFromV44ToV45),
  Migration(46, upgradeFromV45ToV46),
  Migration(47, upgradeFromV46ToV47),
  Migration(48, upgradeFromV47ToV48),
  Migration(49, upgradeFromV48ToV49),
  Migration(50, upgradeFromV49ToV50),
];

class DatabaseService {
  /// Logger.
  final Logger _log = Logger('DatabaseService');

  /// The database.
  late Database database;

  Future<void> initialize() async {
    final dbPath = path.join(
      await getDatabasesPath(),
      'moxxy.db',
    );
    final dbPassword =
        await GetIt.I.get<XmppStateService>().getOrCreateDatabaseKey();

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
      password: dbPassword,
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
        final logger = Logger('DatabaseMigration');
        await runMigrations(
          _log,
          (db, logger),
          migrations,
          oldVersion,
          'database',
        );
      },
    );

    _log.finest('Database setup done');
  }
}

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
}
