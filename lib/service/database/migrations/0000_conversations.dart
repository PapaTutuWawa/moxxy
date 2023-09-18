import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/database.dart';

Future<void> upgradeFromV6ToV7(DatabaseMigrationData data) async {
  final (db, _) = data;

  await db.execute(
    'ALTER TABLE $conversationsTable ADD COLUMN lastMessageState INTEGER NOT NULL DEFAULT 0;',
  );
  await db.execute(
    "ALTER TABLE $conversationsTable ADD COLUMN lastMessageSender TEXT NOT NULL DEFAULT '';",
  );
}
