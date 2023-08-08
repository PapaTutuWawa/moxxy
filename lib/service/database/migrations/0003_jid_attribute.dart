import 'package:moxxyv2/service/database/constants.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

extension MaybeGet<K, V> on Map<K, V> {
  V? maybeGet(K? key) {
    if (key == null) return null;

    return this[key];
  }
}

Future<void> upgradeFromV45ToV46(Database db) async {
  // Migrate everything to the tuple of (account JID, <old pk>)
  // Things we do not migrate to this scheme:
  // - Stickers: Technically, makes no sense
  // - File metadata: We want to aggresively cache, so we keep it

  // Get the account JID
  final rawJid = await db.query(
    xmppStateTable,
    where: 'key = ?',
    whereArgs: ['jid'],
    limit: 1,
  );
  if (rawJid.isEmpty) {
    // TODO: Remove all messages?
  }
  final accountJid = rawJid.first['value']! as String;

  // Migrate the XMPP state
  await db.execute(
    '''
    CREATE TABLE ${xmppStateTable}_new (
      key        TEXT NOT NULL,
      accountJid TEXT NOT NULL,
      value TEXT,
      PRIMARY KEY (key, accountJid)
    )''',
  );
  for (final statePair in await db.query(xmppStateTable)) {
    await db.insert(
      '${xmppStateTable}_new',
      {
        ...statePair,
        'accountJid': accountJid,
      },
    );
  }
  await db.execute('DROP TABLE $xmppStateTable');
  await db
      .execute('ALTER TABLE ${xmppStateTable}_new RENAME TO $xmppStateTable');

  // Migrate messages
  await db.execute(
    '''
    CREATE TABLE ${messagesTable}_new (
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
      pseudoMessageType        INTEGER,
      pseudoMessageData        TEXT,
      PRIMARY KEY (accountJid, senderJid, sid),
      CONSTRAINT fk_quote
        FOREIGN KEY (accountJid, quote_id)
        REFERENCES $messagesTable (accountJid, sid)
      CONSTRAINT fk_file_metadata
        FOREIGN KEY (file_metadata_id)
        REFERENCES $fileMetadataTable (id)
    ''',
  );
  final messages = await db.query(messagesTable);
  // Build up the message map
  /// Message's old id attribute -> Message's sid attribute.
  final messageMap = <int, String>{};
  for (var message in messages) {
    messageMap[message['id']! as int] = message['sid']! as String;
  }
  // Then migrate messages
  for (final message in messages) {
    await db.insert('${messagesTable}_new', {
      ...message
        ..remove('id')
        ..remove('quote_id'),
      'accountJid': accountJid,
      'quote_id': message
    });
  }
  await db.execute('DROP TABLE $messagesTable');
  await db.execute('ALTER TABLE ${messagesTable}_new RENAME TO $messagesTable');
  await db.execute('DROP INDEX idx_messages_id');
  await db.execute(
      'CREATE INDEX idx_messages_sid ON $messagesTable (accountJid, sid)');
  await db.execute(
      'CREATE INDEX idx_messages_origin_sid ON $messagesTable (accountJid, originId, sid)');

  // Migrate conversations
  await db.execute(
    '''
    CREATE TABLE ${conversationsTable}_new (
      jid                 TEXT NOT NULL,
      accountJid          TEXT NOT NULL,
      title               TEXT NOT NULL,
      avatarPath          TEXT NOT NULL,
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
        FOREIGN KEY (accountJid, lastMessageId)
        REFERENCES $messagesTable (accountJid, sid),
      CONSTRAINT fk_contact_id
        FOREIGN KEY (contactId)
        REFERENCES $contactsTable (id)
        ON DELETE SET NULL
    )''',
  );
  for (final conversation in await db.query(conversationsTable)) {
    await db.insert(
      '${conversationsTable}_new',
      {
        ...conversation..remove('lastMessageId'),
        'lastMessageId':
            messageMap.maybeGet(conversation['lastMessageId'] as int?),
        'accountJid': accountJid,
      },
    );
  }
  await db.execute('DROP TABLE $conversationsTable');
  await db.execute(
      'ALTER TABLE ${conversationsTable}_new RENAME TO $conversationsTable');
  await db.execute('DROP INDEX idx_conversation_id');
  await db.execute(
      'CREATE INDEX idx_conversation_id ON $conversationsTable (accountJid, jid)');

  // Migrate reactions
  await db.execute(
    '''
    CREATE TABLE ${reactionsTable}_new (
      accountJid TEXT NOT NULL,
      senderJid  TEXT NOT NULL,
      emoji      TEXT NOT NULL,
      message_id TEXT NOT NULL,
      PRIMARY KEY (accountJid, senderJid, emoji, message_id),
      CONSTRAINT fk_message
        FOREIGN KEY (accountJid, message_id)
        REFERENCES $messagesTable (accountJid, sid)
        ON DELETE CASCADE
    )''',
  );
  for (final reaction in await db.query(reactionsTable)) {
    await db.insert(
      '${reactionsTable}_new',
      {
        ...reaction..remove('message_id'),
        'message_id': messageMap.maybeGet(reaction['message_id'] as int?),
        'accountJid': accountJid,
      },
    );
  }

  // Migrate the roster
  await db.execute(
    '''
    CREATE TABLE ${rosterTable}_new (
      jid                TEXT NOT NULL,
      accountJid         TEXT NOT NULL,
      title              TEXT NOT NULL,
      avatarPath         TEXT NOT NULL,
      avatarHash         TEXT NOT NULL,
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
  for (final rosterItem in await db.query(rosterTable)) {
    await db.insert(
      '${rosterTable}_new',
      {
        ...rosterItem..remove('id'),
        'accountJid': accountJid,
      },
    );
  }
  await db.execute('DROP TABLE $rosterTable');
  await db.execute('ALTER TABLE ${rosterTable}_new RENAME TO $rosterTable');

  // Migrate the blocklist
  await db.execute(
    '''
    CREATE TABLE ${blocklistTable}_new (
      jid        TEXT NOT NULL,
      accountJid TEXT NOT NULL,
      PRIMARY KEY (accountJid, jid)
    );
    ''',
  );
  for (final blocklistItem in await db.query(blocklistTable)) {
    await db.insert(
      '${blocklistTable}_new',
      {
        ...blocklistItem,
        'accountJid': accountJid,
      },
    );
  }
  await db.execute('DROP TABLE $blocklistTable');
  await db
      .execute('ALTER TABLE ${blocklistTable}_new RENAME TO $blocklistTable');

  // Migrate OMEMO device list
  await db.execute(
    '''
    CREATE TABLE ${omemoDeviceListTable}_new (
      jid        TEXT NOT NULL,
      accountJid TEXT NOT NULL,
      devices    TEXT NOT NULL,
      PRIMARY KEY (accountJid, jid)
    )''',
  );
  for (final deviceListEntry in await db.query(omemoDeviceListTable)) {
    await db.insert(
      '${omemoDeviceListTable}_new',
      {
        ...deviceListEntry,
        'accountJid': accountJid,
      },
    );
  }
  await db.execute('DROP TABLE $omemoDeviceListTable');
  await db.execute(
      'ALTER TABLE ${omemoDeviceListTable}_new RENAME TO $omemoDeviceListTable');

  // Migrate OMEMO trust
  await db.execute(
    '''
    CREATE TABLE ${omemoTrustTable}_new (
      jid        TEXT NOT NULL,
      accountJid TEXT NOT NULL
      device     INTEGER NOT NULL,
      trust      INTEGER NOT NULL,
      enabled    INTEGER NOT NULL,
      PRIMARY KEY (accountJid, jid, device)
    )''',
  );
  for (final trustItem in await db.query(omemoTrustTable)) {
    await db.insert(
      '${omemoTrustTable}_new',
      {
        ...trustItem,
        'accoutJid': accountJid,
      },
    );
  }
  await db.execute('DROP TABLE $omemoTrustTable');
  await db
      .execute('ALTER TABLE ${omemoTrustTable}_new RENAME TO $omemoTrustTable');

  // Migrate OMEMO ratchets
  await db.execute(
    '''
    CREATE TABLE ${omemoRatchetsTable}_new (
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
  for (final ratchet in await db.query(omemoRatchetsTable)) {
    await db.insert(
      '${omemoRatchetsTable}_new',
      {
        ...ratchet,
        'accountJid': accountJid,
      },
    );
  }
  await db.execute('DROP TABLE $omemoRatchetsTable');
  await db.execute(
      'ALTER TABLE ${omemoRatchetsTable}_new RENAME TO $omemoRatchetsTable');
}
