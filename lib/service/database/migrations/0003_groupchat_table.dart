import 'package:moxxyv2/service/database/constants.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

Future<void> upgradeFromV42ToV43(Database db) async {
  await db.execute(
    '''
    CREATE TABLE $groupchatTable (
      jid TEXT PRIMARY KEY,
      nick TEXT NOT NULL
    )''',
  );
}
