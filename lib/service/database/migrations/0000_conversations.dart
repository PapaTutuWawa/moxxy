import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/shared/models/conversation.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

Future<void> upgradeFromV6ToV7(Database db) async {
  await db.execute(
    'ALTER TABLE $conversationsTable ADD COLUMN lastMessageState INTEGER NOT NULL DEFAULT 0;'
  );
  await db.execute(
    "ALTER TABLE $conversationsTable ADD COLUMN lastMessageSender TEXT NOT NULL DEFAULT '';"
  );

}
