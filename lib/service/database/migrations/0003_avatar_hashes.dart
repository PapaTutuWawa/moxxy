import 'package:moxxyv2/service/database/constants.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

Future<void> upgradeFromV37ToV38(Database db) async {
  await db
      .execute('ALTER TABLE $conversationsTable ADD COLUMN avatarHash TEXT');
  await db.execute(
    'ALTER TABLE $conversationsTable RENAME COLUMN avatarUrl TO avatarPath',
  );
  await db.execute(
    'ALTER TABLE $rosterTable RENAME COLUMN avatarUrl TO avatarPath',
  );
}
