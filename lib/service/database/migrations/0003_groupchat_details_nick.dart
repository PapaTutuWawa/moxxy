import 'package:moxxyv2/service/database/constants.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

Future<void> upgradeFromV41ToV42(Database db) async {
  await db.execute(
    'ALTER TABLE $conversationsTable ADD COLUMN nick TEXT DEFAULT NULL;',
  );
}
