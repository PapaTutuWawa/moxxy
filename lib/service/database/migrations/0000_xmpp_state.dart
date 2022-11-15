import 'package:moxxyv2/service/database/constants.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

Future<void> upgradeFromV1ToV2(Database db) async {
  // Create the table
  await db.execute(
    '''
    CREATE TABLE $xmppStateTable (
      key   TEXT PRIMARY KEY,
      value TEXT
    )''',
  );
}
