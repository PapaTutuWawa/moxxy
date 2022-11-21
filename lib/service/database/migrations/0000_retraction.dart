import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/helpers.dart';
import 'package:moxxyv2/shared/models/preference.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

Future<void> upgradeFromV3ToV4(Database db) async {
  // Mark all messages as not retracted
  await db.execute(
    'ALTER TABLE $messsagesTable ADD COLUMN isRetracted INTEGER DEFAULT ${boolToInt(false)};',
  );
}
