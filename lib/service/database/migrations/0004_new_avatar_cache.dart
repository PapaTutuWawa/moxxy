import 'dart:io';
import 'package:moxxyv2/service/avatars.dart';
import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/database.dart';
import 'package:path/path.dart' as p;

Future<void> upgradeFromV47ToV48(DatabaseMigrationData data) async {
  final (db, logger) = data;

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
        'avatarUrl': newPath,
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
    if (migratedAvatars.contains(path)) {
      logger.finest(
        'Skipping conversation avatar $path because it is already migrated',
      );
      continue;
    }

    try {
      final hash = conversation['avatarHash']! as String;
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
    if (migratedAvatars.contains(path)) {
      continue;
    }

    try {
      final hash = rosterItem['avatarHash']! as String;
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
