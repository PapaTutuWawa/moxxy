import 'dart:io';
import 'package:moxxyv2/service/avatars.dart';
import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/database.dart';
import 'package:path/path.dart' as p;

Future<void> upgradeFromV47ToV48(DatabaseMigrationData data) async {
  final (db, logger) = data;

  // Make avatarPath and avatarHash nullable
  // 1) Roster items
  await db.execute(
    '''
    CREATE TABLE ${rosterTable}_new (
      jid                TEXT NOT NULL,
      accountJid         TEXT NOT NULL,
      title              TEXT NOT NULL,
      avatarPath         TEXT,
      avatarHash         TEXT,
      subscription       TEXT NOT NULL,
      ask                TEXT NOT NULL,
      contactId          TEXT,
      contactAvatarPath  TEXT,
      contactDisplayName TEXT,
      pseudoRosterItem   INTEGER NOT NULL,
      CONSTRAINT fk_contact_id
        FOREIGN KEY (contactId)
        REFERENCES $contactsTable (id)
        ON DELETE SET NULL
    )''',
  );
  await db.execute(
    'INSERT INTO ${rosterTable}_new SELECT * from $rosterTable',
  );
  await db.execute('DROP TABLE $rosterTable');
  await db.execute('ALTER TABLE ${rosterTable}_new RENAME TO $rosterTable');
  // 2) Conversations
  await db.execute(
    '''
    CREATE TABLE ${conversationsTable}_new (
      jid                 TEXT NOT NULL,
      accountJid          TEXT NOT NULL,
      title               TEXT NOT NULL,
      avatarPath          TEXT,
      avatarHash          TEXT,
      type                TEXT NOT NULL,
      lastChangeTimestamp INTEGER NOT NULL,
      unreadCounter       INTEGER NOT NULL,
      open                INTEGER NOT NULL,
      muted               INTEGER NOT NULL,
      encrypted           INTEGER NOT NULL,
      lastMessageId       TEXT,
      contactId           TEXT,
      contactAvatarPath   TEXT,
      contactDisplayName  TEXT,
      PRIMARY KEY (jid, accountJid),
      CONSTRAINT fk_last_message
        FOREIGN KEY (lastMessageId)
        REFERENCES $messagesTable (id),
      CONSTRAINT fk_contact_id
        FOREIGN KEY (contactId)
        REFERENCES $contactsTable (id)
        ON DELETE SET NULL
    )''',
  );
  await db.execute(
    'INSERT INTO ${conversationsTable}_new SELECT * from $conversationsTable',
  );
  await db.execute('DROP TABLE $conversationsTable');
  await db.execute(
    'ALTER TABLE ${conversationsTable}_new RENAME TO $conversationsTable',
  );

  // Find all conversations and roster items that have an avatar.
  final conversations = await db.query(
    conversationsTable,
    where: 'avatarPath IS NOT NULL AND avatarHash IS NOT NULL',
  );
  final rosterItems = await db.query(
    rosterTable,
    where: 'avatarPath IS NOT NULL AND avatarHash IS NOT NULL',
  );
  final cachePath = await AvatarService.getCachePath();
  final migratedAvatars = <String>[];

  // Ensure the cache directory exists
  final cacheDir = Directory(cachePath);
  if (!cacheDir.existsSync()) {
    await cacheDir.create(recursive: true);
  }

  // "Migrate" our own avatar.
  final accountAvatars = await db.query(
    xmppStateTable,
    columns: ['value'],
    where: 'key = ? AND value IS NOT NULL',
    whereArgs: ['avatarUrl'],
  );
  for (final avatar in accountAvatars) {
    final oldPath = avatar['value']! as String;
    final newPath = p.join(
      cachePath,
      p.basename(oldPath),
    );

    logger.finest('Migrating account avatar $oldPath');
    await File(oldPath).copy(
      newPath,
    );

    await db.update(
      xmppStateTable,
      {
        'value': newPath,
      },
      where: 'key = ? AND value = ?',
      whereArgs: ['avatarUrl', oldPath],
    );
    // Kinda hacky, but okay
    migratedAvatars.add(
      p.basename(oldPath).split('.').first,
    );
  }

  // Migrate conversation avatars.
  for (final conversation in conversations) {
    final path = conversation['avatarPath']! as String;
    final hash = conversation['avatarHash']! as String;
    final jid = conversation['jid']! as String;
    if (migratedAvatars.contains(path)) {
      logger.finest(
        'Skipping conversation avatar $path because it is already migrated',
      );
      continue;
    } else if (path.isEmpty && hash.isEmpty) {
      logger.finest("Migrating conversation $jid's empty avatar data to null");
      await db.update(
        conversationsTable,
        {
          'avatarPath': null,
          'avatarHash': null,
        },
        where: 'jid = ? AND accountJid = ?',
        whereArgs: [
          jid,
          conversation['accountJid']! as String,
        ],
      );
      continue;
    }

    try {
      final newPath = p.join(cachePath, '$hash.png');

      logger.finest(
        'Migrating conversation avatar $path',
      );
      await File(path).copy(newPath);
      await File(path).delete();

      migratedAvatars.add(path);

      // Migrate the database models
      await db.update(
        conversationsTable,
        {
          'avatarPath': newPath,
        },
        where: 'avatarPath = ? AND avatarHash = ?',
        whereArgs: [path, hash],
      );
      await db.update(
        rosterTable,
        {
          'avatarPath': newPath,
        },
        where: 'avatarPath = ? AND avatarHash = ?',
        whereArgs: [path, hash],
      );
    } catch (ex) {
      logger.warning('Failed to migrate avatar $path: $ex');
    }
  }

  // Migrate roster item avatars.
  for (final rosterItem in rosterItems) {
    final path = rosterItem['avatarPath']! as String;
    final hash = rosterItem['avatarHash']! as String;
    final jid = rosterItem['jid']! as String;

    if (migratedAvatars.contains(path)) {
      logger.finest(
        'Skipping roster avatar $path because it is already migrated',
      );
      continue;
    } else if (path.isEmpty && hash.isEmpty) {
      logger.finest(
        "Migrating roster item $jid's empty avatar data to null",
      );
      await db.update(
        rosterTable,
        {
          'avatarPath': null,
          'avatarHash': null,
        },
        where: 'jid = ? AND accountJid = ?',
        whereArgs: [
          jid,
          rosterItem['accountJid']! as String,
        ],
      );
      continue;
    }

    try {
      final newPath = p.join(cachePath, '$hash.png');

      logger.finest(
        'Migrating roster avatar $path',
      );
      await File(path).copy(newPath);
      await File(path).delete();

      migratedAvatars.add(path);

      // Migrate the database models
      await db.update(
        conversationsTable,
        {
          'avatarPath': newPath,
        },
        where: 'avatarPath = ? AND avatarHash = ?',
        whereArgs: [path, hash],
      );
      await db.update(
        rosterTable,
        {
          'avatarPath': newPath,
        },
        where: 'avatarPath = ? AND avatarHash = ?',
        whereArgs: [path, hash],
      );
    } catch (ex) {
      logger.warning('Failed to migrate avatar $path: $ex');
    }
  }
}
