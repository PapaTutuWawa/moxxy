import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/database.dart';

Future<void> upgradeFromV14ToV15(DatabaseMigrationData data) async {
  final (db, _) = data;

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
