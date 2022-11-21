import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/helpers.dart';
import 'package:moxxyv2/shared/models/preference.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

Future<void> upgradeFromV4ToV5(Database db) async {
  // Give all conversations a pseudo last message data
  await db.execute(
    'ALTER TABLE $conversationsTable ADD COLUMN lastMessageId INTEGER NOT NULL DEFAULT 0;',
  );
  await db.execute(
    'ALTER TABLE $conversationsTable ADD COLUMN lastMessageRetracted INTEGER NOT NULL DEFAULT ${boolToInt(false)};',
  );
}
