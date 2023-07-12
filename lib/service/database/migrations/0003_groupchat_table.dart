import 'package:moxxyv2/service/database/constants.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

Future<void> upgradeFromV41ToV42(Database db) async {
  await db.execute(
    '''
    CREATE TABLE $groupchatTable (
      jid TEXT PRIMARY KEY,
      nick TEXT NOT NULL,
      title TEXT NOT NULL
    )''',
  );
}
