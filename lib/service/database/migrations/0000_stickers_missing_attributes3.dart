import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/helpers.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

Future<void> upgradeFromV21ToV22(Database db) async {
  await db.execute(
    'ALTER TABLE $stickersTable DROP COLUMN suggests;',
  );

  await db.execute(
    'ALTER TABLE $stickersTable ADD COLUMN suggests TEXT NOT NULL DEFAULT "{}";',
  );
}
