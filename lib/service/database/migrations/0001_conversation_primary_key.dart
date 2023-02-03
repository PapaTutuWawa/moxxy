import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/shared/models/preference.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

Future<void> upgradeFromV27ToV28(Database db) async {
  // Collect conversations so that we have a mapping id -> jid
  final idMap = <int, String>{};
  final conversations = await db.query(conversationsTable);
  for (final c in conversations) {
    idMap[c['id']! as int] = c['jid']! as String;
  }

  // Migrate the conversations
  await db.execute(
    '''
    CREATE TABLE ${conversationsTable}_new (
      jid TEXT NOT NULL PRIMARY KEY,
      title TEXT NOT NULL,
      avatarUrl TEXT NOT NULL,
      lastChangeTimestamp INTEGER NOT NULL,
      unreadCounter INTEGER NOT NULL,
      open INTEGER NOT NULL,
      muted INTEGER NOT NULL,
      encrypted INTEGER NOT NULL,
      lastMessageId INTEGER,
      contactId TEXT,
      contactAvatarPath TEXT,
      contactDisplayName TEXT,
      CONSTRAINT fk_last_message FOREIGN KEY (lastMessageId) REFERENCES $messagesTable (id),
      CONSTRAINT fk_contact_id FOREIGN KEY (contactId) REFERENCES $contactsTable (id)
        ON DELETE SET NULL
    )''',
  );
  await db.execute('INSERT INTO ${conversationsTable}_new SELECT jid, title, avatarUrl, lastChangeTimestamp, unreadCounter, open, muted, encrypted, lastMessageId, contactid, contactAvatarPath, contactDisplayName from $conversationsTable');
  await db.execute('DROP TABLE $conversationsTable;');
  await db.execute('ALTER TABLE ${conversationsTable}_new RENAME TO $conversationsTable;');

  // Add the jid column to shared media
  await db.execute("ALTER TABLE $mediaTable ADD COLUMN conversation_jid TEXT NOT NULL DEFAULT '';");

  // Update all shared media items
  for (final entry in idMap.entries) {
    await db.update(
      mediaTable,
      {
        'conversation_jid': entry.value,
      },
      where: 'conversation_id = ?',
      whereArgs: [entry.key],
    );
  }

  // Migrate shared media
  await db.execute(
    '''
    CREATE TABLE ${mediaTable}_new (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      path TEXT NOT NULL,
      mime TEXT,
      timestamp INTEGER NOT NULL,
      conversation_jid TEXT NOT NULL,
      message_id INTEGER,
      FOREIGN KEY (conversation_jid) REFERENCES $conversationsTable (jid),
      FOREIGN KEY (message_id) REFERENCES $messagesTable (id)
    )''',
  );
  await db.execute('INSERT INTO ${mediaTable}_new SELECT id, path, mime, timestamp, message_id, conversation_jid from $mediaTable');
  await db.execute('DROP TABLE $mediaTable;');
  await db.execute('ALTER TABLE ${mediaTable}_new RENAME TO $mediaTable;');
}
