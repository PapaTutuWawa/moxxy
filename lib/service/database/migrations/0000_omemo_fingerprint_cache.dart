import 'package:moxxyv2/service/database/constants.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

Future<void> upgradeFromV12ToV13(Database db) async {
  await db.execute(
    '''
    CREATE TABLE $omemoFingerprintCache (
      jid  TEXT NOT NULL,
      id   INTEGER NOT NULL,
      fingerprint TEXT NOT NULL,
      PRIMARY KEY (jid, id)
    )''',
  );
}
