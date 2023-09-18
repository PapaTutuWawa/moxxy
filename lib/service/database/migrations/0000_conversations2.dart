import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/database.dart';

Future<void> upgradeFromV7ToV8(DatabaseMigrationData data) async {
  final (db, _) = data;

  await db.execute(
    'ALTER TABLE $conversationsTable DROP COLUMN lastMessageState;',
  );
  await db.execute(
    'ALTER TABLE $conversationsTable DROP COLUMN lastMessageSender;',
  );
  await db.execute(
    'ALTER TABLE $conversationsTable DROP COLUMN lastMessageBody;',
  );
  await db.execute(
    'ALTER TABLE $conversationsTable DROP COLUMN lastMessageRetracted;',
  );
}
