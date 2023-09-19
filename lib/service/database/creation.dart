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
      key        TEXT NOT NULL,
      accountJid TEXT NOT NULL,
      value TEXT,
      PRIMARY KEY (key, accountJid)
    )''',
  );

  // Messages
  await db.execute(
    '''
    CREATE TABLE $messagesTable (
      id                       TEXT NOT NULL PRIMARY KEY,
      accountJid               TEXT NOT NULL,
      sender                   TEXT NOT NULL,
      body                     TEXT,
      timestamp                INTEGER NOT NULL,
      sid                      TEXT NOT NULL,
      conversationJid          TEXT NOT NULL,
      isFileUploadNotification INTEGER NOT NULL,
      encrypted                INTEGER NOT NULL,
      errorType                INTEGER,
      warningType              INTEGER,
      received                 INTEGER,
      displayed                INTEGER,
      acked                    INTEGER,
      originId                 TEXT,
      quote_id                 TEXT,
      file_metadata_id         TEXT,
      isDownloading            INTEGER NOT NULL,
      isUploading              INTEGER NOT NULL,
      isRetracted              INTEGER,
      isEdited                 INTEGER NOT NULL,
      containsNoStore          INTEGER NOT NULL,
      stickerPackId            TEXT,
      occupantId               TEXT,
      pseudoMessageType        INTEGER,
      pseudoMessageData        TEXT,
      CONSTRAINT fk_quote
        FOREIGN KEY (quote_id)
        REFERENCES $messagesTable (id)
      CONSTRAINT fk_file_metadata
        FOREIGN KEY (file_metadata_id)
        REFERENCES $fileMetadataTable (id)
    )''',
  );
  await db.execute(
    'CREATE INDEX idx_messages_id ON $messagesTable (id, sid, originId)',
  );

  // Reactions
  await db.execute(
    '''
    CREATE TABLE $reactionsTable (
      accountJid TEXT NOT NULL,
      message_id TEXT NOT NULL,
      senderJid  TEXT NOT NULL,
      emoji      TEXT NOT NULL,
      PRIMARY KEY (accountJid, senderJid, emoji, message_id),
      CONSTRAINT fk_message
        FOREIGN KEY (message_id)
        REFERENCES $messagesTable (id)
        ON DELETE CASCADE
    )''',
  );
  await db.execute(
    'CREATE INDEX idx_reactions_message_id ON $reactionsTable (message_id, accountJid, senderJid)',
  );

  // Notifications
  await db.execute(
    '''
    CREATE TABLE $notificationsTable (
      id              INTEGER NOT NULL,
      conversationJid TEXT NOT NULL,
      accountJid      TEXT NOT NULL,
      sender          TEXT,
      senderJid       TEXT,
      avatarPath      TEXT,
      body            TEXT NOT NULL,
      mime            TEXT,
      path            TEXT,
      timestamp       INTEGER NOT NULL,
      PRIMARY KEY (id, conversationJid, senderJid, timestamp, accountJid)
    )''',
  );
  await db.execute(
    'CREATE INDEX idx_notifications ON $notificationsTable (conversationJid, accountJid)',
  );

  // File metadata
  await db.execute(
    '''
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
    )''',
  );
  await db.execute(
    '''
    CREATE TABLE $fileMetadataHashesTable (
      algorithm TEXT NOT NULL,
      value     TEXT NOT NULL,
      id        TEXT NOT NULL,
      CONSTRAINT f_primarykey PRIMARY KEY (algorithm, value),
      CONSTRAINT fk_id FOREIGN KEY (id) REFERENCES $fileMetadataTable (id)
        ON DELETE CASCADE
    )''',
  );
  await db.execute(
    'CREATE INDEX idx_file_metadata_message_id ON $fileMetadataTable (id)',
  );

  // Conversations
  await db.execute(
    '''
    CREATE TABLE $conversationsTable (
      jid                 TEXT NOT NULL,
      accountJid          TEXT NOT NULL,
      title               TEXT NOT NULL,
      avatarPath          TEXT,
      avatarHash          TEXT,
      type                TEXT NOT NULL,
      lastChangeTimestamp INTEGER NOT NULL,
      unreadCounter       INTEGER NOT NULL,
      open                INTEGER NOT NULL,
      muted               INTEGER NOT NULL,
      encrypted           INTEGER NOT NULL,
      lastMessageId       TEXT,
      contactId           TEXT,
      contactAvatarPath   TEXT,
      contactDisplayName  TEXT,
      PRIMARY KEY (jid, accountJid),
      CONSTRAINT fk_last_message
        FOREIGN KEY (lastMessageId)
        REFERENCES $messagesTable (id),
      CONSTRAINT fk_contact_id
        FOREIGN KEY (contactId)
        REFERENCES $contactsTable (id)
        ON DELETE SET NULL
    )''',
  );
  await db.execute(
    'CREATE INDEX idx_conversation_id ON $conversationsTable (jid, accountJid)',
  );

  // Contacts
  await db.execute(
    '''
    CREATE TABLE $contactsTable (
      id TEXT PRIMARY KEY,
      jid TEXT NOT NULL
    )''',
  );

  // Roster
  await db.execute(
    '''
    CREATE TABLE $rosterTable (
      jid                TEXT NOT NULL,
      accountJid         TEXT NOT NULL,
      title              TEXT NOT NULL,
      avatarPath         TEXT,
      avatarHash         TEXT,
      subscription       TEXT NOT NULL,
      ask                TEXT NOT NULL,
      contactId          TEXT,
      contactAvatarPath  TEXT,
      contactDisplayName TEXT,
      pseudoRosterItem   INTEGER NOT NULL,
      CONSTRAINT fk_contact_id
        FOREIGN KEY (contactId)
        REFERENCES $contactsTable (id)
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
      restricted     INTEGER NOT NULL,
      addedTimestamp INTEGER NOT NULL
    )''',
  );

  // Blocklist
  await db.execute(
    '''
    CREATE TABLE $blocklistTable (
      jid        TEXT NOT NULL,
      accountJid TEXT NOT NULL,
      PRIMARY KEY (accountJid, jid)
    );
    ''',
  );

  // OMEMO
  await db.execute(
    '''
    CREATE TABLE $omemoDevicesTable (
      jid       TEXT NOT NULL PRIMARY KEY,
      id        INTEGER NOT NULL,
      ikPub     TEXT NOT NULL,
      ik        TEXT NOT NULL,
      spkPub    TEXT NOT NULL,
      spk       TEXT NOT NULL,
      spkId     INTEGER NOT NULL,
      spkSig    TEXT NOT NULL,
      oldSpkPub TEXT,
      oldSpk    TEXT,
      oldSpkId  INTEGER,
      opks      TEXT NOT NULL
    )''',
  );
  await db.execute(
    '''
    CREATE TABLE $omemoDeviceListTable (
      jid        TEXT NOT NULL,
      accountJid TEXT NOT NULL,
      devices    TEXT NOT NULL,
      PRIMARY KEY (accountJid, jid)
    )''',
  );
  await db.execute(
    '''
    CREATE TABLE $omemoRatchetsTable (
      jid        TEXT NOT NULL,
      accountJid TEXT NOT NULL,
      device     INTEGER NOT NULL,
      dhsPub     TEXT NOT NULL,
      dhs        TEXT NOT NULL,
      dhrPub     TEXT,
      rk         TEXT NOT NULL,
      cks        TEXT,
      ckr        TEXT,
      ns         INTEGER NOT NULL,
      nr         INTEGER NOT NULL,
      pn         INTEGER NOT NULL,
      ik         TEXT NOT NULL,
      ad         TEXT NOT NULL,
      skipped    TEXT NOT NULL,
      kex        TEXT NOT NULL,
      acked      INTEGER NOT NULL,
      PRIMARY KEY (accountJid, jid, device)
    )''',
  );
  await db.execute(
    '''
    CREATE TABLE $omemoTrustTable (
      jid        TEXT NOT NULL,
      accountJid TEXT NOT NULL,
      device     INTEGER NOT NULL,
      trust      INTEGER NOT NULL,
      enabled    INTEGER NOT NULL,
      PRIMARY KEY (accountJid, jid, device)
    )''',
  );

  // Settings
  await db.execute(
    '''
    CREATE TABLE $preferenceTable (
      key TEXT NOT NULL PRIMARY KEY,
      type INTEGER NOT NULL,
      value TEXT NULL
    )''',
  );

  // Groupchat
  await db.execute(
    '''
    CREATE TABLE $groupchatTable (
      jid        TEXT NOT NULL,
      accountJid TEXT NOT NULL,
      nick       TEXT NOT NULL,
      PRIMARY KEY (jid, accountJid),
      CONSTRAINT fk_groupchat
        FOREIGN KEY (jid, accountJid)
        REFERENCES $conversationsTable (jid, accountJid)
        ON DELETE CASCADE
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
      null,
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
