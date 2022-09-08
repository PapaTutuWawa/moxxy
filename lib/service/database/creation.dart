import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/shared/models/preference.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

Future<void> configureDatabase(Database db) async {
  await db.execute('PRAGMA foreign_keys = ON');
}

Future<void> createDatabase(Database db, int version) async {
  // Messages
  await db.execute(
    '''
    CREATE TABLE $messsagesTable (
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
      CONSTRAINT fk_quote FOREIGN KEY (quote_id) REFERENCES $messsagesTable (id)
    )''',
  );

  // Conversations
  await db.execute(
    '''
    CREATE TABLE $conversationsTable (
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
    CREATE TABLE $mediaTable (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      path TEXT NOT NULL,
      mime TEXT,
      timestamp INTEGER NOT NULL,
      conversation_id INTEGER NOT NULL,
      FOREIGN KEY (conversation_id) REFERENCES $conversationsTable (id)
    )''',
  );

  // Roster
  await db.execute(
    '''
    CREATE TABLE $rosterTable (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      jid TEXT NOT NULL,
      title TEXT NOT NULL,
      avatarUrl TEXT NOT NULL,
      avatarHash TEXT NOT NULL,
      subscription TEXT NOT NULL,
      ask TEXT NOT NULL
    )''',
  );

  // Settings
  await db.execute(
    '''
    CREATE TABLE $preferenceTable (
      key TEXT NOT NULL PRIMARY KEY,
      type INTEGER NOT NULL,
      value TEXT NOT NULL,
    );
    ''',
  );
  await db.insert(
    preferenceTable,
    Preference(
      'sendChatMarkers',
      typeBool,
      'true',
    ).toDatabaseJson(),
  );
  await db.insert(
    preferenceTable,
    Preference(
      'sendChatStates',
      typeBool,
      'true',
    ).toDatabaseJson(),
  );
  await db.insert(
    preferenceTable,
    Preference(
      'showSubscriptionRequests',
      typeBool,
      'true',
    ).toDatabaseJson(),
  );
  await db.insert(
    preferenceTable,
    Preference(
      'autoDownloadWifi',
      typeBool,
      'true',
    ).toDatabaseJson(),
  );
  await db.insert(
    preferenceTable,
    Preference(
      'autoDownloadMobile',
      typeBool,
      'false',
    ).toDatabaseJson(),
  );
  await db.insert(
    preferenceTable,
    Preference(
      'maximumAutoDownloadSize',
      typeInt,
      '15',
    ).toDatabaseJson(),
  );
  await db.insert(
    preferenceTable,
    Preference(
      'backgroundPath',
      typeString,
      '',
    ).toDatabaseJson(),
  );
  await db.insert(
    preferenceTable,
    Preference(
      'isAvatarPublic',
      typeBool,
      'true',
    ).toDatabaseJson(),
  );
  await db.insert(
    preferenceTable,
    Preference(
      'autoAcceptSubscriptionRequests',
      typeBool,
      'false',
    ).toDatabaseJson(),
  );
  await db.insert(
    preferenceTable,
    Preference(
      'debugEnabled',
      typeBool,
      'false',
    ).toDatabaseJson(),
  );
  await db.insert(
    preferenceTable,
    Preference(
      'debugPassphrase',
      typeString,
      '',
    ).toDatabaseJson(),
  );
  await db.insert(
    preferenceTable,
    Preference(
      'debugIp',
      typeString,
      '',
    ).toDatabaseJson(),
  );
  await db.insert(
    preferenceTable,
    Preference(
      'debugPort',
      typeInt,
      '-1',
    ).toDatabaseJson(),
  );
  await db.insert(
    preferenceTable,
    Preference(
      'twitterRedirect',
      typeString,
      '',
    ).toDatabaseJson(),
  );
  await db.insert(
    preferenceTable,
    Preference(
      'youtubeRedirect',
      typeString,
      '',
    ).toDatabaseJson(),
  );
  await db.insert(
    preferenceTable,
    Preference(
      'enableTwitterRedirect',
      typeBool,
      'false',
    ).toDatabaseJson(),
  );
  await db.insert(
    preferenceTable,
    Preference(
      'enableYoutubeRedirect',
      typeBool,
      'false',
    ).toDatabaseJson(),
  );
  await db.insert(
    preferenceTable,
    Preference(
      'defaultMuteState',
      typeBool,
      'false',
    ).toDatabaseJson(),
  );
}
