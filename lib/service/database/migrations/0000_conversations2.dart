import 'package:moxxyv2/service/database/constants.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

Future<void> upgradeFromV7ToV8(Database db) async {
  await db
      .execute('ALTER TABLE $conversationsTable DROP COLUMN lastMessageState;');
  await db.execute(
      "ALTER TABLE $conversationsTable DROP COLUMN lastMessageSender;");
  await db
      .execute("ALTER TABLE $conversationsTable DROP COLUMN lastMessageBody;");
  await db.execute(
      "ALTER TABLE $conversationsTable DROP COLUMN lastMessageRetracted;");
}
