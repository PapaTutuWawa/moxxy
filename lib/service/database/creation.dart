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
      conversationJid TEXT NOT NULL,
      isMedia INTEGER NOT NULL,
      isFileUploadNotification INTEGER NOT NULL,
      errorType INTEGER,
      mediaUrl TEXT,
      mediaType TEXT,
      thumbnailData TEXT,
      thumbnailDimensions TEXT,
      dimensions TEXT,
      srcUrl TEXT,
      received INTEGER,
      displayed INTEGER,
      acked INTEGER,
      originId TEXT,
      quote_id INTEGER,
      filename TEXT,
      FOREIGN KEY (quote_id) REFERENCES Messages (id)
    )''',
  );

  // Conversations
  await db.execute(
    '''
    CREATE TABLE Conversations (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      jid TEXT NOT NULL,
      title TEXT NOT NULL,
      avatarUrl TEXT NOT NULL,
      lastChangeTimestamp INTEGER NOT NULL,
      unreadCounter INTEGER NOT NULL,
      lastMessageBody TEXT NOT NULL,
      open INTEGER NOT NULL,
      muted INTEGER NOT NULL
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
      FOREIGN KEY (conversation_id) REFERENCES Conversations (id)
    )''',
  );

  // Roster
  await db.execute(
    '''
    CREATE TABLE RosterItems (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      jid TEXT NOT NULL,
      title TEXT NOT NULL,
      avatarUrl TEXT NOT NULL,
      avatarHash TEXT NOT NULL,
      subscription TEXT NOT NULL,
      ask TEXT NOT NULL
    )''',
  );
}
