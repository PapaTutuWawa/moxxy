import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/helpers.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

Future<void> upgradeFromV19ToV20(Database db) async {
  await db.execute(
    'ALTER TABLE $stickerPacksTable ADD COLUMN restricted DEFAULT ${boolToInt(false)};',
  );
  await db.execute(
    'ALTER TABLE $stickersTable ADD COLUMN suggests DEFAULT "";',
  );
}
