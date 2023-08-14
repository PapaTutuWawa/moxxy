import 'package:get_it/get_it.dart';
import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/xmpp_state.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:uuid/uuid.dart';

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

  // [migrateRows] indicates whether we can move the data to the new JID-annotated format.
  // It's false if we don't have a "logged in" JID. If we have one, it's true and we can
  // move data.
  final migrateRows = rawJid.isNotEmpty;
  final accountJid = migrateRows ? rawJid.first['value']! as String : null;

  // Store the account JID in the secure storage.
  if (migrateRows) {
    await GetIt.I.get<XmppStateService>().setAccountJid(accountJid!);
  }

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
  if (migrateRows) {
    for (final statePair in await db.query(xmppStateTable)) {
      await db.insert(
        '${xmppStateTable}_new',
        {
          ...statePair,
          'accountJid': accountJid,
        },
      );
    }
  }
  await db.execute('DROP TABLE $xmppStateTable');
  await db
      .execute('ALTER TABLE ${xmppStateTable}_new RENAME TO $xmppStateTable');

  // Migrate messages
  await db.execute(
    '''
    CREATE TABLE ${messagesTable}_new (
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
  // Build up the message map
  /// Message's old id attribute -> Message's new UUID attribute.
  const uuid = Uuid();
  final messageMap = <int, String>{};

  if (migrateRows) {
    final messages = await db.query(messagesTable);
    for (final message in messages) {
      messageMap[message['id']! as int] = uuid.v4();
    }
    // Then migrate messages
    for (final message in messages) {
      await db.insert('${messagesTable}_new', {
        ...Map.from(message)
          ..remove('id')
          ..remove('quote_id'),
        'accountJid': accountJid,
        'quote_id': messageMap.maybeGet(message['quote_id'] as int?),
        'id': messageMap[message['id']! as int],
      });
    }
  }
  await db.execute('DROP TABLE $messagesTable');
  await db.execute('ALTER TABLE ${messagesTable}_new RENAME TO $messagesTable');
  await db.execute(
    'CREATE INDEX idx_messages_sid ON $messagesTable (accountJid, sid)',
  );
  await db.execute(
    'CREATE INDEX idx_messages_origin_sid ON $messagesTable (accountJid, originId, sid)',
  );

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
        FOREIGN KEY (lastMessageId)
        REFERENCES $messagesTable (id),
      CONSTRAINT fk_contact_id
        FOREIGN KEY (contactId)
        REFERENCES $contactsTable (id)
        ON DELETE SET NULL
    )''',
  );
  if (migrateRows) {
    for (final conversation in await db.query(conversationsTable)) {
      await db.insert(
        '${conversationsTable}_new',
        {
          ...Map.from(conversation)..remove('lastMessageId'),
          'lastMessageId':
              messageMap.maybeGet(conversation['lastMessageId'] as int?),
          'accountJid': accountJid,
        },
      );
    }
  }
  await db.execute('DROP TABLE $conversationsTable');
  await db.execute(
    'ALTER TABLE ${conversationsTable}_new RENAME TO $conversationsTable',
  );
  await db.execute(
    'CREATE INDEX idx_conversation_id ON $conversationsTable (accountJid, jid)',
  );

  // Migrate groupchat details
  await db.execute(
    '''
    CREATE TABLE ${groupchatTable}_new (
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
  if (migrateRows) {
    for (final g in await db.query(groupchatTable)) {
      await db.insert(
        '${groupchatTable}_new',
        {
          ...g,
          'accountJid': accountJid,
        },
      );
    }
  }
  await db.execute('DROP TABLE $groupchatTable');
  await db
      .execute('ALTER TABLE ${groupchatTable}_new RENAME TO $groupchatTable');

  // Migrate reactions
  await db.execute(
    '''
    CREATE TABLE ${reactionsTable}_new (
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
  if (migrateRows) {
    for (final reaction in await db.query(reactionsTable)) {
      await db.insert(
        '${reactionsTable}_new',
        {
          ...Map.from(reaction)..remove('message_id'),
          'message_id': messageMap.maybeGet(reaction['message_id']! as int),
          'accountJid': accountJid,
        },
      );
    }
  }
  await db.execute('DROP TABLE $reactionsTable');
  await db
      .execute('ALTER TABLE ${reactionsTable}_new RENAME TO $reactionsTable');

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
  if (migrateRows) {
    for (final rosterItem in await db.query(rosterTable)) {
      await db.insert(
        '${rosterTable}_new',
        {
          ...Map.from(rosterItem)..remove('id'),
          'accountJid': accountJid,
        },
      );
    }
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
  if (migrateRows) {
    for (final blocklistItem in await db.query(blocklistTable)) {
      await db.insert(
        '${blocklistTable}_new',
        {
          ...blocklistItem,
          'accountJid': accountJid,
        },
      );
    }
  }
  await db.execute('DROP TABLE $blocklistTable');
  await db
      .execute('ALTER TABLE ${blocklistTable}_new RENAME TO $blocklistTable');

  // Migrate the notifications list
  await db.execute(
    '''
    CREATE TABLE ${notificationsTable}_new (
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
  if (migrateRows) {
    for (final notification in await db.query(notificationsTable)) {
      await db.insert(
        '${notificationsTable}_new',
        {
          ...notification,
          'accountJid': accountJid,
        },
      );
    }
  }
  await db.execute('DROP TABLE $notificationsTable');
  await db.execute(
    'ALTER TABLE ${notificationsTable}_new RENAME TO $notificationsTable',
  );

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
  {
    for (final deviceListEntry in await db.query(omemoDeviceListTable)) {
      await db.insert(
        '${omemoDeviceListTable}_new',
        {
          ...deviceListEntry,
          'accountJid': accountJid,
        },
      );
    }
  }
  await db.execute('DROP TABLE $omemoDeviceListTable');
  await db.execute(
    'ALTER TABLE ${omemoDeviceListTable}_new RENAME TO $omemoDeviceListTable',
  );

  // Migrate OMEMO trust
  await db.execute(
    '''
    CREATE TABLE ${omemoTrustTable}_new (
      jid        TEXT NOT NULL,
      accountJid TEXT NOT NULL,
      device     INTEGER NOT NULL,
      trust      INTEGER NOT NULL,
      enabled    INTEGER NOT NULL,
      PRIMARY KEY (accountJid, jid, device)
    )''',
  );
  if (migrateRows) {
    for (final trustItem in await db.query(omemoTrustTable)) {
      await db.insert(
        '${omemoTrustTable}_new',
        {
          ...trustItem,
          'accoutJid': accountJid,
        },
      );
    }
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
  if (migrateRows) {
    for (final ratchet in await db.query(omemoRatchetsTable)) {
      await db.insert(
        '${omemoRatchetsTable}_new',
        {
          ...ratchet,
          'accountJid': accountJid,
        },
      );
    }
  }
  await db.execute('DROP TABLE $omemoRatchetsTable');
  await db.execute(
    'ALTER TABLE ${omemoRatchetsTable}_new RENAME TO $omemoRatchetsTable',
  );
}
