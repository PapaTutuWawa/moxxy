import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/shared/models/preference.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

Future<void> configureDatabase(Database db) async {
  await db.execute('PRAGMA foreign_keys = OFF');
}

Future<void> createDatabase(Database db, int version) async {
  // XMPP state
  await db.execute(
    '''
    CREATE TABLE $xmppStateTable (
      key   TEXT PRIMARY KEY,
      value TEXT
    )''',
  );

  // Messages
  await db.execute(
    '''
    CREATE TABLE $messagesTable (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      sender TEXT NOT NULL,
      body TEXT,
      timestamp INTEGER NOT NULL,
      sid TEXT NOT NULL,
      conversationJid TEXT NOT NULL,
      isMedia INTEGER NOT NULL,
      isFileUploadNotification INTEGER NOT NULL,
      encrypted INTEGER NOT NULL,
      errorType INTEGER,
      warningType INTEGER,
      mediaUrl TEXT,
      mediaType TEXT,
      thumbnailData TEXT,
      mediaWidth INTEGER,
      mediaHeight INTEGER,
      srcUrl TEXT,
      key TEXT,
      iv TEXT,
      encryptionScheme TEXT,
      received INTEGER,
      displayed INTEGER,
      acked INTEGER,
      originId TEXT,
      quote_id INTEGER,
      filename TEXT,
      plaintextHashes TEXT,
      ciphertextHashes TEXT,
      isDownloading INTEGER NOT NULL,
      isUploading INTEGER NOT NULL,
      mediaSize INTEGER,
      isRetracted INTEGER,
      isEdited INTEGER NOT NULL,
      reactions TEXT NOT NULL,
      containsNoStore INTEGER NOT NULL,
      CONSTRAINT fk_quote FOREIGN KEY (quote_id) REFERENCES $messagesTable (id)
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

  // Contacts
  await db.execute(
    '''
    CREATE TABLE $contactsTable (
      id TEXT PRIMARY KEY,
      jid TEXT NOT NULL
    )'''
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
      message_id INTEGER,
      FOREIGN KEY (conversation_id) REFERENCES $conversationsTable (id),
      FOREIGN KEY (message_id) REFERENCES $messagesTable (id)
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
      ask TEXT NOT NULL,
      contactId TEXT,
      CONSTRAINT fk_contact_id FOREIGN KEY (contactId) REFERENCES $contactsTable (id)
        ON DELETE SET NULL
    )''',
  );

  // OMEMO
  await db.execute(
    '''
    CREATE TABLE $omemoRatchetsTable (
      id         INTEGER NOT NULL,
      jid        TEXT NOT NULL,
      dhs        TEXT NOT NULL,
      dhs_pub    TEXT NOT NULL,
      dhr        TEXT,
      rk         TEXT NOT NULL,
      cks        TEXT,
      ckr        TEXT,
      ns         INTEGER NOT NULL,
      nr         INTEGER NOT NULL,
      pn         INTEGER NOT NULL,
      ik_pub     TEXT NOT NULL,
      session_ad TEXT NOT NULL,
      acknowledged INTEGER NOT NULL,
      mkskipped  TEXT NOT NULL,
      kex_timestamp INTEGER NOT NULL,
      kex        TEXT,
      PRIMARY KEY (jid, id)
    )''',
  );
  await db.execute(
    '''
    CREATE TABLE $omemoTrustCacheTable (
      key   TEXT PRIMARY KEY NOT NULL,
      trust INTEGER NOT NULL
    )''',
  );
  await db.execute(
    '''
    CREATE TABLE $omemoTrustDeviceListTable (
      jid    TEXT NOT NULL,
      device INTEGER NOT NULL
    )''',
  );
  await db.execute(
    '''
    CREATE TABLE $omemoTrustEnableListTable (
      key     TEXT PRIMARY KEY NOT NULL,
      enabled INTEGER NOT NULL
    )''',
  );
  await db.execute(
    '''
    CREATE TABLE $omemoDeviceTable (
      jid  TEXT NOT NULL,
      id   INTEGER NOT NULL,
      data TEXT NOT NULL,
      PRIMARY KEY (jid, id)
    )''',
  );
  await db.execute(
    '''
    CREATE TABLE $omemoDeviceListTable (
      jid  TEXT NOT NULL,
      id   INTEGER NOT NULL,
      PRIMARY KEY (jid, id)
    )''',
  );
  await db.execute(
    '''
    CREATE TABLE $omemoFingerprintCache (
      jid  TEXT NOT NULL,
      id   INTEGER NOT NULL,
      fingerprint TEXT NOT NULL,
      PRIMARY KEY (jid, id)
    )''',
  );

  // Settings
  await db.execute(
    '''
    CREATE TABLE $preferenceTable (
      key TEXT NOT NULL PRIMARY KEY,
      type INTEGER NOT NULL,
      value TEXT NOT NULL
    )''',
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
  await db.insert(
    preferenceTable,
    Preference(
      'enableOmemoByDefault',
      typeBool,
      'false',
    ).toDatabaseJson(),
  );
  await db.insert(
    preferenceTable,
    Preference(
      'languageLocaleCode',
      typeString,
      'default',
    ).toDatabaseJson(),
  );
  await db.insert(
    preferenceTable,
    Preference(
      'enableContactIntegration',
      typeBool,
      'false',
    ).toDatabaseJson(),
  );
}
