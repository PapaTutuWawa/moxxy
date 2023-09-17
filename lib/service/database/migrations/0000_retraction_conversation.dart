import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/database.dart';
import 'package:moxxyv2/service/database/helpers.dart';

Future<void> upgradeFromV4ToV5(DatabaseMigrationData data) async {
  final (db, _) = data;

  // Give all conversations a pseudo last message data
  await db.execute(
    'ALTER TABLE $conversationsTable ADD COLUMN lastMessageId INTEGER NOT NULL DEFAULT 0;',
  );
  await db.execute(
    'ALTER TABLE $conversationsTable ADD COLUMN lastMessageRetracted INTEGER NOT NULL DEFAULT ${boolToInt(false)};',
  );
}
