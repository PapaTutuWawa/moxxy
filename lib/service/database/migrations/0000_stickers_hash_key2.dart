import 'package:moxxyv2/service/database/constants.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

Future<void> upgradeFromV18ToV19(Database db) async {
  await db.execute(
    'ALTER TABLE $stickerPacksTable DROP COLUMN stickerHashKey;',
  );
}
