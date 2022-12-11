import 'package:moxxyv2/service/database/constants.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

Future<void> upgradeFromV14ToV15(Database db) async {
  await db.execute(
    'ALTER TABLE $conversationsTable ADD COLUMN contactAvatarPath TEXT DEFAULT NULL;',
  );
  await db.execute(
    'ALTER TABLE $rosterTable ADD COLUMN contactAvatarPath TEXT DEFAULT NULL;',
  );
  await db.execute(
    'ALTER TABLE $conversationsTable ADD COLUMN contactDisplayName TEXT DEFAULT NULL;',
  );
  await db.execute(
    'ALTER TABLE $rosterTable ADD COLUMN contactDisplayName TEXT DEFAULT NULL;',
  );
}
