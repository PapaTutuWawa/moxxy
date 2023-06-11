import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/helpers.dart';
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
  await db.execute('''
    CREATE TABLE $messagesTable (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      sender TEXT NOT NULL,
      body TEXT,
      timestamp INTEGER NOT NULL,
      sid TEXT NOT NULL,
      conversationJid TEXT NOT NULL,
      isFileUploadNotification INTEGER NOT NULL,
      encrypted INTEGER NOT NULL,
      errorType INTEGER,
      warningType INTEGER,
      received INTEGER,
      displayed INTEGER,
      acked INTEGER,
      originId TEXT,
      quote_id INTEGER,
      file_metadata_id TEXT,
      isDownloading INTEGER NOT NULL,
      isUploading INTEGER NOT NULL,
      isRetracted INTEGER,
      isEdited INTEGER NOT NULL,
      containsNoStore INTEGER NOT NULL,
      stickerPackId   TEXT,
      pseudoMessageType INTEGER,
      pseudoMessageData TEXT,
      CONSTRAINT fk_quote FOREIGN KEY (quote_id) REFERENCES $messagesTable (id)
      CONSTRAINT fk_file_metadata FOREIGN KEY (file_metadata_id) REFERENCES $fileMetadataTable (id)
    )''');
  await db.execute(
    'CREATE INDEX idx_messages_id ON $messagesTable (id, sid, originId)',
  );

  // Reactions
  await db.execute('''
    CREATE TABLE $reactionsTable (
      senderJid  TEXT NOT NULL,
      emoji      TEXT NOT NULL,
      message_id INTEGER NOT NULL,
      CONSTRAINT pk_sender PRIMARY KEY (senderJid, emoji, message_id),
      CONSTRAINT fk_message FOREIGN KEY (message_id) REFERENCES $messagesTable (id)
        ON DELETE CASCADE
    )''');
  await db.execute(
    'CREATE INDEX idx_reactions_message_id ON $reactionsTable (message_id, senderJid)',
  );

  // File metadata
  await db.execute('''
    CREATE TABLE $fileMetadataTable (
      id               TEXT NOT NULL PRIMARY KEY,
      path             TEXT,
      sourceUrls       TEXT,
      mimeType         TEXT,
      thumbnailType    TEXT,
      thumbnailData    TEXT,
      width            INTEGER,
      height           INTEGER,
      plaintextHashes  TEXT,
      encryptionKey    TEXT,
      encryptionIv     TEXT,
      encryptionScheme TEXT,
      cipherTextHashes TEXT,
      filename         TEXT NOT NULL,
      size             INTEGER
    )''');
  await db.execute('''
    CREATE TABLE $fileMetadataHashesTable (
      algorithm TEXT NOT NULL,
      value     TEXT NOT NULL,
      id        TEXT NOT NULL,
      CONSTRAINT f_primarykey PRIMARY KEY (algorithm, value),
      CONSTRAINT fk_id FOREIGN KEY (id) REFERENCES $fileMetadataTable (id)
        ON DELETE CASCADE
    )''');
  await db.execute(
    'CREATE INDEX idx_file_metadata_message_id ON $fileMetadataTable (id)',
  );

  // Conversations
  await db.execute(
    '''
    CREATE TABLE $conversationsTable (
      jid TEXT NOT NULL PRIMARY KEY,
      title TEXT NOT NULL,
      avatarUrl TEXT NOT NULL,
      type TEXT NOT NULL,
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
  await db.execute(
    'CREATE INDEX idx_conversation_id ON $conversationsTable (jid)',
  );

  // Contacts
  await db.execute('''
    CREATE TABLE $contactsTable (
      id TEXT PRIMARY KEY,
      jid TEXT NOT NULL
    )''');

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
      contactAvatarPath TEXT,
      contactDisplayName TEXT,
      pseudoRosterItem INTEGER NOT NULL,
      CONSTRAINT fk_contact_id FOREIGN KEY (contactId) REFERENCES $contactsTable (id)
        ON DELETE SET NULL
    )''',
  );

  // Stickers
  await db.execute(
    '''
    CREATE TABLE $stickersTable (
      id               TEXT PRIMARY KEY,
      desc             TEXT NOT NULL,
      suggests         TEXT NOT NULL,
      file_metadata_id TEXT NOT NULL,
      stickerPackId  TEXT NOT NULL,
      CONSTRAINT fk_sticker_pack FOREIGN KEY (stickerPackId) REFERENCES $stickerPacksTable (id)
        ON DELETE CASCADE,
      CONSTRAINT fk_file_metadata FOREIGN KEY (file_metadata_id) REFERENCES $fileMetadataTable (id)
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
      restricted     INTEGER NOT NULL
    )''',
  );

  // Blocklist
  await db.execute(
    '''
    CREATE TABLE $blocklistTable (
      jid TEXT PRIMARY KEY
    );
    ''',
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
  await db.insert(
    preferenceTable,
    Preference(
      'isStickersNodePublic',
      typeBool,
      'true',
    ).toDatabaseJson(),
  );
  await db.insert(
    preferenceTable,
    Preference(
      'showDebugMenu',
      typeBool,
      boolToString(false),
    ).toDatabaseJson(),
  );
}
