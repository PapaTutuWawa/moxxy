import 'package:sqflite_sqlcipher/sqflite.dart';

Future<void> configureDatabase(Database db) async {
  await db.execute('PRAGMA foreign_keys = ON');
}

Future<void> createDatabase(Database db, int version) async {
  // Messages
  await db.execute(
    '''
    CREATE TABLE Messages (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      sender TEXT NOT NULL,
      body TEXT,
      timestamp INTEGER NOT NULL,
      sid TEXT NOT NULL,
      conversation_jid TEXT NOT NULL,
      is_media INTEGER NOT NULL,
      is_file_upload_notification INTEGER NOT NULL,
      error_type INTEGER,
      media_url TEXT,
      media_type TEXT,
      thumbnail_data TEXT,
      thumbnail_dimensions TEXT,
      dimensions TEXT,
      src_url TEXT,
      received INTEGER,
      displayed INTEGER,
      acked INTEGER,
      origin_id TEXT,
      quote_id INTEGER,
      filename TEXT,
      FOREIGN KEY (quote_id) REFERENCES Messages (id),
    )''',
  );

  // Conversations
  await db.execute(
    '''
    CREATE TABLE Conversations (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      jid TEXT NOT NULL,
      title TEXT NOT NULL,
      avatar_url TEXT NOT NULL,
      last_change_timestamp INTEGER NOT NULL,
      unread_counter INTEGER NOT NULL,
      last_message_body TEXT NOT NULL,
      open INTEGER NOT NULL,
      muted INTEGER NOT NULL,
    )''',
  );

  // Shared media
  await db.execute(
    '''
    CREATE TABLE SharedMedia (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      path TEXT NOT NULL,
      mime TEXT,
      timestamp INTEGER NOT NULL,
      conversation_id INTEGER NOT NULL,
      FOREIGN KEY (conversation_id) REFERENCES Conversations (id),
    )''',
  );

  // Roster
  await db.execute(
    '''
    CREATE TABLE RosterItems (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      jid TEXT NOT NULL,
      title TEXT NOT NULL,
      avatar_hash TEXT NOT NULL,
      subscription TEXT NOT NULL,
      ask TEXT NOT NULL,
    )''',
  );
}
