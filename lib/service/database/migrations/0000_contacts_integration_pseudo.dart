import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/helpers.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

Future<void> upgradeFromV15ToV16(Database db) async {
  await db.execute(
    'ALTER TABLE $rosterTable ADD COLUMN pseudoRosterItem INTEGER NOT NULL DEFAULT ${boolToInt(false)};',
  );
}
