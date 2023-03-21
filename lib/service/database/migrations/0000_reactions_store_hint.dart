import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/helpers.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

Future<void> upgradeFromV11ToV12(Database db) async {
  await db.execute(
      'ALTER TABLE $messagesTable ADD COLUMN containsNoStore INTEGER NOT NULL DEFAULT ${boolToInt(false)};',);
}
