import 'package:moxxyv2/service/database/constants.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

Future<void> upgradeFromV43ToV44(Database db) async {
  await db.execute(
    '''
    CREATE TABLE $notificationsTable (
      id              INTEGER NOT NULL,
      conversationJid TEXT NOT NULL,
      sender          TEXT,
      senderJid       TEXT,
      avatarPath      TEXT,
      body            TEXT NOT NULL,
      mime            TEXT,
      path            TEXT,
      timestamp       INTEGER NOT NULL,
      PRIMARY KEY (id, conversationJid, senderJid, timestamp)
    )''',
  );
  await db.execute(
    'CREATE INDEX idx_notifications ON $notificationsTable (conversationJid)',
  );
}
