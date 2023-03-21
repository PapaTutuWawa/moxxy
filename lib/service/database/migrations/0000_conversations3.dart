import 'package:moxxyv2/service/database/constants.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

Future<void> upgradeFromV8ToV9(Database db) async {
  // Step 1
  //await db.execute('PRAGMA foreign_keys = 0;');

  // Step 2
  // Step 4
  await db.execute(
    '''
      CREATE TABLE ${conversationsTable}_new (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      jid TEXT NOT NULL,
      title TEXT NOT NULL,
      avatarUrl TEXT NOT NULL,
      lastChangeTimestamp INTEGER NOT NULL,
      unreadCounter INTEGER NOT NULL,
      open INTEGER NOT NULL,
      muted INTEGER NOT NULL,
      encrypted INTEGER NOT NULL,
      lastMessageId INTEGER,
      CONSTRAINT fk_last_message FOREIGN KEY (lastMessageId) REFERENCES $messagesTable (id)
      )''',
  );

  // Step 5
  await db.execute(
      'INSERT INTO ${conversationsTable}_new SELECT * from $conversationsTable',);

  // Step 6
  await db.execute('DROP TABLE $conversationsTable;');

  // Step 7
  await db.execute(
      'ALTER TABLE ${conversationsTable}_new RENAME TO $conversationsTable;',);

  // Step 10
  //await db.execute('PRAGMA foreign_key_check;');

  // Step 11

  // Step 12
  //await db.execute('PRAGMA foreign_keys=ON;');
}
