import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/database.dart';

Future<void> upgradeFromV17ToV18(DatabaseMigrationData data) async {
  final (db, _) = data;

  // Update messages
  await db.execute(
    'ALTER TABLE $messagesTable DROP COLUMN stickerId;',
  );
  await db.execute(
    'ALTER TABLE $messagesTable ADD COLUMN stickerHashKey TEXT;',
  );

  // Drop stickers
  await db.execute('DROP TABLE $stickerPacksTable;');
  await db.execute('DROP TABLE $stickersTable;');

  await db.execute(
    '''
    CREATE TABLE $stickersTable (
      hashKey       TEXT PRIMARY KEY,
      mediaType     TEXT NOT NULL,
      desc          TEXT NOT NULL,
      size          INTEGER NOT NULL,
      width         INTEGER,
      height        INTEGER,
      hashes        TEXT NOT NULL,
      urlSources    TEXT NOT NULL,
      path          TEXT NOT NULL,
      stickerPackId TEXT NOT NULL,
      CONSTRAINT fk_sticker_pack FOREIGN KEY (stickerPackId) REFERENCES $stickerPacksTable (id)
        ON DELETE CASCADE
    )''',
  );
  await db.execute(
    '''
    CREATE TABLE $stickerPacksTable (
      id             TEXT PRIMARY KEY,
      name           TEXT NOT NULL,
      description    TEXT NOT NULL,
      hashAlgorithm  TEXT NOT NULL,
      hashValue      TEXT NOT NULL,
      stickerHashKey TEXT NOT NULL
    )''',
  );
}
