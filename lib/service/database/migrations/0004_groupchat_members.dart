import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/database.dart';

Future<void> upgradeFromV48ToV49(DatabaseMigrationData data) async {
  final (db, _) = data;

  await db.execute(
    '''
    CREATE TABLE $groupchatMembersTable (
      roomJid             TEXT NOT NULL,
      accountJid          TEXT NOT NULL,
      nick                TEXT NOT NULL,
      role                TEXT NOT NULL,
      affiliation         TEXT NOT NULL,
      avatarPath          TEXT,
      avatarHash          TEXT,
      realJid             TEXT,
      PRIMARY KEY (roomJid, accountJid, nick),
      CONSTRAINT fk_muc
        FOREIGN KEY (roomJid, accountJid)
        REFERENCES $conversationsTable (jid, accountJid)
        ON DELETE CASCADE
    )''',
  );
  await db.execute(
    'CREATE INDEX idx_members ON $groupchatMembersTable (roomJid, accountJid)',
  );
}
