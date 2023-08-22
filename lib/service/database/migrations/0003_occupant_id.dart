import 'package:moxxyv2/service/database/constants.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

Future<void> upgradeFromV46ToV47(Database db) async {
  await db.execute(
    'ALTER TABLE $messagesTable ADD COLUMN occupantId TEXT',
  );
}
