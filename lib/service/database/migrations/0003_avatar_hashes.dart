import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/database.dart';

Future<void> upgradeFromV37ToV38(DatabaseMigrationData data) async {
  final (db, _) = data;

  await db
      .execute('ALTER TABLE $conversationsTable ADD COLUMN avatarHash TEXT');
  await db.execute(
    'ALTER TABLE $conversationsTable RENAME COLUMN avatarUrl TO avatarPath',
  );
  await db.execute(
    'ALTER TABLE $rosterTable RENAME COLUMN avatarUrl TO avatarPath',
  );
}
