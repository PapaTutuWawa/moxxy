import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/database.dart';
import 'package:moxxyv2/shared/models/preference.dart';

Future<void> upgradeFromV13ToV14(DatabaseMigrationData data) async {
  final (db, _) = data;

  // Create the new table
  await db.execute('''
    CREATE TABLE $contactsTable (
      id TEXT PRIMARY KEY,
      jid TEXT NOT NULL
    )''');

  // Migrate the conversations
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
      contactId TEXT,
      CONSTRAINT fk_last_message FOREIGN KEY (lastMessageId) REFERENCES $messagesTable (id),
      CONSTRAINT fk_contact_id FOREIGN KEY (contactId) REFERENCES $contactsTable (id)
        ON DELETE SET NULL
    )''',
  );
  await db.execute(
    'INSERT INTO ${conversationsTable}_new SELECT *, NULL from $conversationsTable',
  );
  await db.execute('DROP TABLE $conversationsTable;');
  await db.execute(
    'ALTER TABLE ${conversationsTable}_new RENAME TO $conversationsTable;',
  );

  // Migrate the roster items
  await db.execute(
    '''
    CREATE TABLE ${rosterTable}_new (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      jid TEXT NOT NULL,
      title TEXT NOT NULL,
      avatarUrl TEXT NOT NULL,
      avatarHash TEXT NOT NULL,
      subscription TEXT NOT NULL,
      ask TEXT NOT NULL,
      contactId TEXT,
      CONSTRAINT fk_contact_id FOREIGN KEY (contactId) REFERENCES $contactsTable (id)
        ON DELETE SET NULL
    )''',
  );
  await db.execute(
    'INSERT INTO ${rosterTable}_new SELECT *, NULL from $rosterTable',
  );
  await db.execute('DROP TABLE $rosterTable;');
  await db.execute('ALTER TABLE ${rosterTable}_new RENAME TO $rosterTable;');

  // Introduce the new preference key
  await db.insert(
    preferenceTable,
    Preference(
      'enableContactIntegration',
      typeBool,
      'false',
    ).toDatabaseJson(),
  );
}
