import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/database.dart';
import 'package:moxxyv2/shared/models/preference.dart';

Future<void> upgradeFromV16ToV17(DatabaseMigrationData data) async {
  final (db, _) = data;

  await db.execute(
    '''
    CREATE TABLE $stickersTable (
      id            INTEGER PRIMARY KEY AUTOINCREMENT,
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
      id            TEXT PRIMARY KEY,
      name          TEXT NOT NULL,
      description   TEXT NOT NULL,
      hashAlgorithm TEXT NOT NULL,
      hashValue     TEXT NOT NULL
    )''',
  );

  // Add the sticker attributes to Messages
  await db.execute(
    'ALTER TABLE $messagesTable ADD COLUMN stickerPackId TEXT;',
  );
  await db.execute(
    'ALTER TABLE $messagesTable ADD COLUMN stickerId INTEGER;',
  );

  // Add the new preferences
  await db.insert(
    preferenceTable,
    Preference(
      'enableStickers',
      typeBool,
      'true',
    ).toDatabaseJson(),
  );
  await db.insert(
    preferenceTable,
    Preference(
      'autoDownloadStickersFromContacts',
      typeBool,
      'true',
    ).toDatabaseJson(),
  );
}
