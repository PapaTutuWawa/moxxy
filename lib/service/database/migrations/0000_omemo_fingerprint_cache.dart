import 'package:moxxyv2/service/database/database.dart';

Future<void> upgradeFromV12ToV13(DatabaseMigrationData data) async {
  final (db, _) = data;

  await db.execute(
    '''
    CREATE TABLE OmemoFingerprintCache (
      jid  TEXT NOT NULL,
      id   INTEGER NOT NULL,
      fingerprint TEXT NOT NULL,
      PRIMARY KEY (jid, id)
    )''',
  );
}
