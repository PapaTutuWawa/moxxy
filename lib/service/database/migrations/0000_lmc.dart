import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/helpers.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

Future<void> upgradeFromV9ToV10(Database db) async {
  // Mark all messages as not edited
  await db.execute(
    'ALTER TABLE $messagesTable ADD COLUMN isEdited INTEGER NOT NULL DEFAULT ${boolToInt(false)};',
  );
}
