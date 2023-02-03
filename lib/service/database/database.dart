import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxyv2/service/database/constants.dart';
import 'package:moxxyv2/service/database/creation.dart';
import 'package:moxxyv2/service/database/helpers.dart';
import 'package:moxxyv2/service/database/migrations/0000_blocklist.dart';
import 'package:moxxyv2/service/database/migrations/0000_contacts_integration.dart';
import 'package:moxxyv2/service/database/migrations/0000_contacts_integration_avatar.dart';
import 'package:moxxyv2/service/database/migrations/0000_contacts_integration_pseudo.dart';
import 'package:moxxyv2/service/database/migrations/0000_conversations.dart';
import 'package:moxxyv2/service/database/migrations/0000_conversations2.dart';
import 'package:moxxyv2/service/database/migrations/0000_conversations3.dart';
import 'package:moxxyv2/service/database/migrations/0000_language.dart';
import 'package:moxxyv2/service/database/migrations/0000_lmc.dart';
import 'package:moxxyv2/service/database/migrations/0000_omemo_fingerprint_cache.dart';
import 'package:moxxyv2/service/database/migrations/0000_pseudo_messages.dart';
import 'package:moxxyv2/service/database/migrations/0000_reactions.dart';
import 'package:moxxyv2/service/database/migrations/0000_reactions_store_hint.dart';
import 'package:moxxyv2/service/database/migrations/0000_retraction.dart';
import 'package:moxxyv2/service/database/migrations/0000_retraction_conversation.dart';
import 'package:moxxyv2/service/database/migrations/0000_shared_media.dart';
import 'package:moxxyv2/service/database/migrations/0000_stickers.dart';
import 'package:moxxyv2/service/database/migrations/0000_stickers_hash_key.dart';
import 'package:moxxyv2/service/database/migrations/0000_stickers_hash_key2.dart';
import 'package:moxxyv2/service/database/migrations/0000_stickers_missing_attributes.dart';
import 'package:moxxyv2/service/database/migrations/0000_stickers_missing_attributes2.dart';
import 'package:moxxyv2/service/database/migrations/0000_stickers_missing_attributes3.dart';
import 'package:moxxyv2/service/database/migrations/0000_stickers_privacy.dart';
import 'package:moxxyv2/service/database/migrations/0000_xmpp_state.dart';
import 'package:moxxyv2/service/database/migrations/0001_conversation_primary_key.dart';
import 'package:moxxyv2/service/database/migrations/0001_debug_menu.dart';
import 'package:moxxyv2/service/database/migrations/0001_remove_auto_accept_subscriptions.dart';
import 'package:moxxyv2/service/database/migrations/0001_subscriptions.dart';
import 'package:moxxyv2/service/helpers.dart';
import 'package:moxxyv2/service/not_specified.dart';
import 'package:moxxyv2/service/omemo/omemo.dart';
import 'package:moxxyv2/service/omemo/types.dart';
import 'package:moxxyv2/service/roster.dart';
import 'package:moxxyv2/shared/models/conversation.dart';
import 'package:moxxyv2/shared/models/media.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/shared/models/preferences.dart';
import 'package:moxxyv2/shared/models/reaction.dart';
import 'package:moxxyv2/shared/models/roster.dart';
import 'package:moxxyv2/shared/models/sticker.dart' as sticker;
import 'package:moxxyv2/shared/models/sticker_pack.dart' as sticker_pack;
import 'package:moxxyv2/shared/models/xmpp_state.dart';
import 'package:omemo_dart/omemo_dart.dart';
import 'package:path/path.dart' as path;
import 'package:random_string/random_string.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

const databasePasswordKey = 'database_encryption_password';

class DatabaseService {
  /// Secure storage for accesing the database encryption key.
  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    // TODO(Unknown): Set other options
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  /// Logger.
  final Logger _log = Logger('DatabaseService');

  /// The database.
  late Database _db;
  
  Future<void> initialize() async {
    final dbPath = path.join(
      await getDatabasesPath(),
      'moxxy.db',
    );

    String key;
    if (await _storage.containsKey(key: databasePasswordKey)) {
      _log.finest('Database encryption key found');
      key = (await _storage.read(key: databasePasswordKey))!;
    } else {
      _log.finest('Database encryption not key found. Generating it...');
      key = randomAlphaNumeric(40, provider: CoreRandomProvider.from(Random.secure()));
      await _storage.write(key: databasePasswordKey, value: key);
      _log.finest('Key generation done...');
    }
    
    _db = await openDatabase(
      dbPath,
      password: key,
      version: 29,
      onCreate: createDatabase,
      onConfigure: (db) async {
        // In order to do schema changes during database upgrades, we disable foreign
        // keys in the onConfigure phase, but re-enable them here.
        // See https://github.com/tekartik/sqflite/issues/624#issuecomment-813324273
        // for the "solution".
        await db.execute('PRAGMA foreign_keys = OFF');
      },
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          _log.finest('Running migration for database version 2');
          await upgradeFromV1ToV2(db);
        }
        if (oldVersion < 3) {
          _log.finest('Running migration for database version 3');
          await upgradeFromV2ToV3(db);
        }
        if (oldVersion < 4) {
          _log.finest('Running migration for database version 4');
          await upgradeFromV3ToV4(db);
        }
        if (oldVersion < 5) {
          _log.finest('Running migration for database version 5');
          await upgradeFromV4ToV5(db);
        }
        if (oldVersion < 6) {
          _log.finest('Running migration for database version 6');
          await upgradeFromV5ToV6(db);
        }
        if (oldVersion < 7) {
          _log.finest('Running migration for database version 7');
          await upgradeFromV6ToV7(db);
        }
        if (oldVersion < 8) {
          _log.finest('Running migration for database version 8');
          await upgradeFromV7ToV8(db);
        }
        if (oldVersion < 9) {
          _log.finest('Running migration for database version 9');
          await upgradeFromV8ToV9(db);
        }
        if (oldVersion < 10) {
          _log.finest('Running migration for database version 10');
          await upgradeFromV9ToV10(db);
        }
        if (oldVersion < 11) {
          _log.finest('Running migration for database version 11');
          await upgradeFromV10ToV11(db);
        }
        if (oldVersion < 12) {
          _log.finest('Running migration for database version 12');
          await upgradeFromV11ToV12(db);
        }
        if (oldVersion < 13) {
          _log.finest('Running migration for database version 13');
          await upgradeFromV12ToV13(db);
        }
        if (oldVersion < 14) {
          _log.finest('Running migration for database version 14');
          await upgradeFromV13ToV14(db);
        }
        if (oldVersion < 15) {
          _log.finest('Running migration for database version 15');
          await upgradeFromV14ToV15(db);
        }
        if (oldVersion < 16) {
          _log.finest('Running migration for database version 16');
          await upgradeFromV15ToV16(db);
        }
        if (oldVersion < 17) {
          _log.finest('Running migration for database version 17');
          await upgradeFromV16ToV17(db);
        }
        if (oldVersion < 18) {
          _log.finest('Running migration for database version 18');
          await upgradeFromV17ToV18(db);
        }
        if (oldVersion < 19) {
          _log.finest('Running migration for database version 19');
          await upgradeFromV18ToV19(db);
        }
        if (oldVersion < 20) {
          _log.finest('Running migration for database version 20');
          await upgradeFromV19ToV20(db);
        }
        if (oldVersion < 21) {
          _log.finest('Running migration for database version 21');
          await upgradeFromV20ToV21(db);
        }
        if (oldVersion < 22) {
          _log.finest('Running migration for database version 22');
          await upgradeFromV21ToV22(db);
        }
        if (oldVersion < 23) {
          _log.finest('Running migration for database version 23');
          await upgradeFromV22ToV23(db);
        }
        if (oldVersion < 24) {
          _log.finest('Running migration for database version 24');
          await upgradeFromV23ToV24(db);
        }
        if (oldVersion < 25) {
          _log.finest('Running migration for database version 25');
          await upgradeFromV24ToV25(db);
        }
        if (oldVersion < 26) {
          _log.finest('Running migration for database version 26');
          await upgradeFromV25ToV26(db);
        }
        if (oldVersion < 27) {
          _log.finest('Running migration for database version 27');
          await upgradeFromV26ToV27(db);
        }
        if (oldVersion < 28) {
          _log.finest('Running migration for database version 28');
          await upgradeFromV27ToV28(db);
        }
        if (oldVersion < 29) {
          _log.finest('Running migration for database version 29');
          await upgradeFromV28ToV29(db);
        }
      },
    );

    _log.finest('Database setup done');
  }
  
  /// Loads all conversations from the database and adds them to the state and cache.
  Future<List<Conversation>> loadConversations() async {
    final conversationsRaw = await _db.query('Conversations',
      orderBy: 'lastChangeTimestamp DESC',
    );
    
    final tmp = List<Conversation>.empty(growable: true);
    for (final c in conversationsRaw) {
      final jid = c['jid']! as String;
      final sharedMediaRaw = await _db.query(
        'SharedMedia',
        where: 'conversation_jid = ?',
        whereArgs: [jid],
        orderBy: 'timestamp DESC',
      );
      final rosterItem = await GetIt.I.get<RosterService>()
        .getRosterItemByJid(jid);

      Message? lastMessage;
      if (c['lastMessageId'] != null) {
        lastMessage = await getMessageById(c['lastMessageId']! as int);
      }
        
      tmp.add(
        Conversation.fromDatabaseJson(
          c,
          rosterItem != null && !rosterItem.pseudoRosterItem,
          rosterItem?.subscription ?? 'none',
          sharedMediaRaw,
          lastMessage,
        ),
      );
    }
    
    return tmp;
  }

  /// Load messages for [jid] from the database.
  Future<List<Message>> loadMessagesForJid(String jid) async {
    final rawMessages = await _db.query(
      'Messages',
      where: 'conversationJid = ?',
      whereArgs: [jid],
      orderBy: 'timestamp ASC',
    );

    final messages = List<Message>.empty(growable: true);
    for (final m in rawMessages) {
      Message? quotes;
      if (m['quote_id'] != null) {
        final rawQuote = (await _db.query(
          'Messages',
          where: 'conversationJid = ? AND id = ?',
          whereArgs: [jid, m['quote_id']! as int],
        )).first;
        quotes = Message.fromDatabaseJson(rawQuote, null);
      }

      messages.add(Message.fromDatabaseJson(m, quotes));
    }

    return messages;
  }
  
  /// Updates the conversation with JID [jid] inside the database.
  Future<Conversation> updateConversation(String jid, {
    int? lastChangeTimestamp,
    Message? lastMessage,
    bool? open,
    int? unreadCounter,
    String? avatarUrl,
    ChatState? chatState,
    bool? muted,
    bool? encrypted,
    Object? contactId = notSpecified,
    Object? contactAvatarPath = notSpecified,
    Object? contactDisplayName = notSpecified,
  }) async {
    final cd = (await _db.query(
      'Conversations',
      where: 'jid = ?',
      whereArgs: [jid],
    )).first;
    final c = Map<String, dynamic>.from(cd);

    final sharedMedia = (await _db.query(
      'SharedMedia',
      where: 'conversation_jid = ?',
      whereArgs: [jid],
      orderBy: 'timestamp DESC',
    )).map(SharedMedium.fromDatabaseJson);
    
    if (lastMessage != null) {
      c['lastMessageId'] = lastMessage.id;
    }
    if (lastChangeTimestamp != null) {
      c['lastChangeTimestamp'] = lastChangeTimestamp;
    }
    if (open != null) {
      c['open'] = boolToInt(open);
    }
    if (unreadCounter != null) {
      c['unreadCounter'] = unreadCounter;
    }
    if (avatarUrl != null) {
      c['avatarUrl'] = avatarUrl;
    }
    if (muted != null) {
      c['muted'] = boolToInt(muted);
    }
    if (encrypted != null) {
      c['encrypted'] = boolToInt(encrypted);
    }
    if (contactId != notSpecified) {
      c['contactId'] = contactId as String?;
    }
    if (contactAvatarPath != notSpecified) {
      c['contactAvatarPath'] = contactAvatarPath as String?;
    }
    if (contactDisplayName != notSpecified) {
      c['contactDisplayName'] = contactDisplayName as String?;
    }

    await _db.update(
      'Conversations',
      c,
      where: 'jid = ?',
      whereArgs: [jid],
    );

    final rosterItem = await GetIt.I.get<RosterService>().getRosterItemByJid(jid);
    return Conversation.fromDatabaseJson(
      c,
      rosterItem != null,
      rosterItem?.subscription ?? 'none',
      sharedMedia.map((m) => m.toJson()).toList(),
      lastMessage,
    );
  }

  /// Creates a [Conversation] inside the database given the data. This is so that the
  /// [Conversation] object can carry its database id.
  Future<Conversation> addConversationFromData(
    String title,
    Message? lastMessage,
    String avatarUrl,
    String jid,
    int unreadCounter,
    int lastChangeTimestamp,
    bool open,
    bool muted,
    bool encrypted,
    String? contactId,
    String? contactAvatarPath,
    String? contactDisplayName,
  ) async {
    final rosterItem = await GetIt.I.get<RosterService>().getRosterItemByJid(jid);
    final conversation = Conversation(
      title,
      lastMessage,
      avatarUrl,
      jid,
      unreadCounter,
      lastChangeTimestamp,
      <SharedMedium>[],
      open,
      rosterItem != null && !rosterItem.pseudoRosterItem,
      rosterItem?.subscription ?? 'none',
      muted,
      encrypted,
      ChatState.gone,
      contactId: contactId,
      contactAvatarPath: contactAvatarPath,
      contactDisplayName: contactDisplayName,
    );

    await _db.insert('Conversations', conversation.toDatabaseJson());
    return conversation;
  }

  /// Like [addConversationFromData] but for [SharedMedium].
  Future<SharedMedium> addSharedMediumFromData(String path, int timestamp, String conversationJid, int messageId, { String? mime }) async {
    final s = SharedMedium(
      -1,
      path,
      timestamp,
      conversationJid,
      mime: mime,
      messageId: messageId,
    );

    return s.copyWith(
      id: await _db.insert('SharedMedia', s.toDatabaseJson()),
    );
  }

  /// Remove a SharedMedium from the database based on the message it
  /// references [messageId].
  Future<void> removeSharedMediumByMessageId(int messageId) async {
    await _db.delete(
      mediaTable,
      where: 'message_id = ?',
      whereArgs: [messageId],
    );
  }
  
  /// Same as [addConversationFromData] but for a [Message].
  Future<Message> addMessageFromData(
    String body,
    int timestamp,
    String sender,
    String conversationJid,
    bool isMedia,
    String sid,
    bool isFileUploadNotification,
    bool encrypted,
    bool containsNoStore,
    {
      String? srcUrl,
      String? key,
      String? iv,
      String? encryptionScheme,
      String? mediaUrl,
      String? mediaType,
      String? thumbnailData,
      int? mediaWidth,
      int? mediaHeight,
      String? originId,
      String? quoteId,
      String? filename,
      int? errorType,
      int? warningType,
      Map<String, String>? plaintextHashes,
      Map<String, String>? ciphertextHashes,
      bool isDownloading = false,
      bool isUploading = false,
      int? mediaSize,
      String? stickerPackId,
      String? stickerHashKey,
      int? pseudoMessageType,
      Map<String, dynamic>? pseudoMessageData,
    }
  ) async {
    var m = Message(
      sender,
      body,
      timestamp,
      sid,
      -1,
      conversationJid,
      isMedia,
      isFileUploadNotification,
      encrypted,
      containsNoStore,
      errorType: errorType,
      warningType: warningType,
      mediaUrl: mediaUrl,
      key: key,
      iv: iv,
      encryptionScheme: encryptionScheme,
      mediaType: mediaType,
      thumbnailData: thumbnailData,
      mediaWidth: mediaWidth,
      mediaHeight: mediaHeight,
      srcUrl: srcUrl,
      received: false,
      displayed: false,
      acked: false,
      originId: originId,
      filename: filename,
      plaintextHashes: plaintextHashes,
      ciphertextHashes: ciphertextHashes,
      isUploading: isUploading,
      isDownloading: isDownloading,
      mediaSize: mediaSize,
      stickerPackId: stickerPackId,
      stickerHashKey: stickerHashKey,
      pseudoMessageType: pseudoMessageType,
      pseudoMessageData: pseudoMessageData,
    );

    if (quoteId != null) {
      final quotes = await getMessageByXmppId(quoteId, conversationJid);
      if (quotes == null) {
        _log.warning('Failed to add quote for message with id $quoteId');
      } else {
        m = m.copyWith(quotes: quotes);
      }
    }

    return m.copyWith(
      id: await _db.insert('Messages', m.toDatabaseJson()),
    );
  }

  Future<Message?> getMessageById(int id) async {
    final messagesRaw = await _db.query(
      'Messages',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (messagesRaw.isEmpty) return null;

    // TODO(PapaTutuWawa): Load the quoted message
    final msg = messagesRaw.first;
    return Message.fromDatabaseJson(msg, null);
  }
  
  Future<Message?> getMessageByXmppId(String id, String conversationJid) async {
    final messagesRaw = await _db.query(
      'Messages',
      where: 'conversationJid = ? AND (sid = ? or originId = ?)',
      whereArgs: [conversationJid, id, id],
      limit: 1,
    );

    if (messagesRaw.isEmpty) return null;

    // TODO(PapaTutuWawa): Load the quoted message
    final msg = messagesRaw.first;
    return Message.fromDatabaseJson(msg, null);
  }

  Future<Message?> getMessageByOriginId(String id, String conversationJid) async {
    final messagesRaw = await _db.query(
      'Messages',
      where: 'conversationJid = ? AND originId = ?',
      whereArgs: [conversationJid, id],
      limit: 1,
    );

    if (messagesRaw.isEmpty) return null;

    // TODO(PapaTutuWawa): Load the quoted message
    final msg = messagesRaw.first;
    return Message.fromDatabaseJson(msg, null);
  }

  /// Updates the message item with id [id] inside the database.
  Future<Message> updateMessage(int id, {
    Object? body = notSpecified,
    Object? mediaUrl = notSpecified,
    Object? mediaType = notSpecified,
    bool? isMedia,
    bool? received,
    bool? displayed,
    bool? acked,
    Object? errorType = notSpecified,
    Object? warningType = notSpecified,
    bool? isFileUploadNotification,
    Object? srcUrl = notSpecified,
    Object? key = notSpecified,
    Object? iv = notSpecified,
    Object? encryptionScheme = notSpecified,
    Object? mediaWidth = notSpecified,
    Object? mediaHeight = notSpecified,
    bool? isDownloading,
    bool? isUploading,
    Object? mediaSize = notSpecified,
    Object? originId = notSpecified,
    Object? sid = notSpecified,
    bool? isRetracted,
    Object? thumbnailData = notSpecified,
    bool? isEdited,
    Object? reactions = notSpecified,
  }) async {
    final md = (await _db.query(
      'Messages',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    )).first;
    final m = Map<String, dynamic>.from(md);

    if (body != notSpecified) {
      m['body'] = body as String?;
    }
    if (mediaUrl != notSpecified) {
      m['mediaUrl'] = mediaUrl as String?;
    }
    if (mediaType != notSpecified) {
      m['mediaType'] = mediaType as String?;
    }
    if (isMedia != null) {
      m['isMedia'] = boolToInt(isMedia);
    }
    if (received != null) {
      m['received'] = boolToInt(received);
    }
    if (displayed != null) {
      m['displayed'] = boolToInt(displayed);
    }
    if (acked != null) {
      m['acked'] = boolToInt(acked);
    }
    if (errorType != notSpecified) {
      m['errorType'] = errorType as int?;
    }
    if (warningType != notSpecified) {
      m['warningType'] = warningType as int?;
    }
    if (isFileUploadNotification != null) {
      m['isFileUploadNotification'] = boolToInt(isFileUploadNotification);
    }
    if (srcUrl != notSpecified) {
      m['srcUrl'] = srcUrl as String?;
    }
    if (mediaWidth != notSpecified) {
      m['mediaWidth'] = mediaWidth as int?;
    }
    if (mediaHeight != notSpecified) {
      m['mediaHeight'] = mediaHeight as int?;
    }
    if (mediaSize != notSpecified) {
      m['mediaSize'] = mediaSize as int?;
    }
    if (key != notSpecified) {
      m['key'] = key as String?;
    }
    if (iv != notSpecified) {
      m['iv'] = iv as String?;
    }
    if (encryptionScheme != notSpecified) {
      m['encryptionScheme'] = encryptionScheme as String?;
    }
    if (isDownloading != null) {
      m['isDownloading'] = boolToInt(isDownloading);
    }
    if (isUploading != null) {
      m['isUploading'] = boolToInt(isUploading);
    }
    if (sid != notSpecified) {
      m['sid'] = sid as String?;
    }
    if (originId != notSpecified) {
      m['originId'] = originId as String?;
    }
    if (isRetracted != null) {
      m['isRetracted'] = boolToInt(isRetracted);
    }
    if (thumbnailData != notSpecified) {
      m['thumbnailData'] = thumbnailData as String?;
    }
    if (isEdited != null) {
      m['isEdited'] = boolToInt(isEdited);
    }
    if (reactions != notSpecified) {
      assert(reactions != null, 'Cannot set reactions to null');
      m['reactions'] = jsonEncode(
        (reactions! as List<Reaction>)
          .map((r) => r.toJson())
          .toList(),
      );
    }

    await _db.update(
      'Messages',
      m,
      where: 'id = ?',
      whereArgs: [id],
    );

    Message? quotes;
    if (m['quote_id'] != null) {
      quotes = await getMessageById(m['quote_id']! as int);
    }
    
    return Message.fromDatabaseJson(m, quotes);
  }
  
  /// Loads roster items from the database
  Future<List<RosterItem>> loadRosterItems() async {
    final items = await _db.query('RosterItems');

    return items.map(RosterItem.fromDatabaseJson).toList();
  }

  /// Removes a roster item from the database and cache
  Future<void> removeRosterItem(int id) async {
    await _db.delete(
      'RosterItems',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Create a roster item from data
  Future<RosterItem> addRosterItemFromData(
    String avatarUrl,
    String avatarHash,
    String jid,
    String title,
    String subscription,
    String ask,
    bool pseudoRosterItem,
    String? contactId,
    String? contactAvatarPath,
    String? contactDisplayName,
    {
      List<String> groups = const [],
    }
  ) async {
    // TODO(PapaTutuWawa): Handle groups
    final i = RosterItem(
      -1,
      avatarUrl,
      avatarHash,
      jid,
      title,
      subscription,
      ask,
      pseudoRosterItem,
      <String>[],
      contactId: contactId,
      contactAvatarPath: contactAvatarPath,
      contactDisplayName: contactDisplayName,
    );

    return i.copyWith(
      id: await _db.insert('RosterItems', i.toDatabaseJson()),
    );
  }

  /// Updates the roster item with id [id] inside the database.
  Future<RosterItem> updateRosterItem(
    int id, {
      String? avatarUrl,
      String? avatarHash,
      String? title,
      String? subscription,
      String? ask,
      Object pseudoRosterItem = notSpecified,
      List<String>? groups,
      Object? contactId = notSpecified,
      Object? contactAvatarPath = notSpecified,
      Object? contactDisplayName = notSpecified,
    }
  ) async {
    final id_ = (await _db.query(
      rosterTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    )).first;
    final i = Map<String, dynamic>.from(id_);

    if (avatarUrl != null) {
      i['avatarUrl'] = avatarUrl;
    }
    if (avatarHash != null) {
      i['avatarHash'] = avatarHash;
    }
    if (title != null) {
      i['title'] = title;
    }
    /*
    if (groups != null) {
      i.groups = groups;
    }
    */
    if (subscription != null) {
      i['subscription'] = subscription;
    }
    if (ask != null) {
      i['ask'] = ask;
    }
    if (contactId != notSpecified) {
      i['contactId'] = contactId as String?;
    }
    if (contactAvatarPath != notSpecified) {
      i['contactAvatarPath'] = contactAvatarPath as String?;
    }
    if (contactDisplayName != notSpecified) {
      i['contactDisplayName'] = contactDisplayName as String?;
    }
    if (pseudoRosterItem != notSpecified) {
      i['pseudoRosterItem'] = boolToInt(pseudoRosterItem as bool);
    }

    await _db.update(
      rosterTable,
      i,
      where: 'id = ?',
      whereArgs: [id],
    );
    return RosterItem.fromDatabaseJson(i);
  }

  Future<PreferencesState> getPreferences() async {
    final preferencesRaw = (await _db.query(preferenceTable))
      .map((preference) {
        switch (preference['type']! as int) {
          case typeInt: return {
            ...preference,
            'value': stringToInt(preference['value']! as String),
          };
          case typeBool: return {
            ...preference,
            'value': stringToBool(preference['value']! as String),
          };
          case typeString:
          default: return preference;
        }
      }).toList();
    final json = <String, dynamic>{};
    for (final preference in preferencesRaw) {
      json[preference['key']! as String] = preference['value'];
    }

    return PreferencesState.fromJson(json);
  }

  Future<void> savePreferences(PreferencesState state) async {
    final stateJson = state.toJson();
    final preferences = stateJson.keys
      .map((key) {
        int type;
        String value;
        if (stateJson[key] is int) {
          type = typeInt;
          value = intToString(stateJson[key]! as int);
        } else if (stateJson[key] is bool) {
          type = typeBool;
          value = boolToString(stateJson[key]! as bool);
        } else {
          type = typeString;
          value = stateJson[key]! as String;
        }

        return {
          'key': key,
          'type': type,
          'value': value,
        };
      });

    final batch = _db.batch();

    for (final preference in preferences) {
      batch.update(
        preferenceTable,
        preference,
        where: 'key = ?',
        whereArgs: [preference['key']],
      );
    }
    
    await batch.commit();
  }

  Future<XmppState> getXmppState() async {
    final json = <String, String?>{};
    for (final row in await _db.query(xmppStateTable)) {
      json[row['key']! as String] = row['value'] as String?;
    }

    return XmppState.fromDatabaseTuples(json);
  }

  Future<void> saveXmppState(XmppState state) async {
    final batch = _db.batch();

    for (final tuple in state.toDatabaseTuples().entries) {
      batch.insert(
        xmppStateTable,
        <String, String?>{ 'key': tuple.key, 'value': tuple.value },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    
    await batch.commit();
  }
  
  Future<void> saveRatchet(OmemoDoubleRatchetWrapper ratchet) async {
    final json = await ratchet.ratchet.toJson();
    await _db.insert(
      omemoRatchetsTable,
      {
        ...json,
        'mkskipped': jsonEncode(json['mkskipped']),
        'acknowledged': boolToInt(json['acknowledged']! as bool),
        'jid': ratchet.jid,
        'id': ratchet.id,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<OmemoDoubleRatchetWrapper>> loadRatchets() async {
    final results = await _db.query(omemoRatchetsTable);

    return results.map((ratchet) {
      final json = jsonDecode(ratchet['mkskipped']! as String) as List<dynamic>;
      final mkskipped = List<Map<String, dynamic>>.empty(growable: true);
      for (final i in json) {
        final element = i as Map<String, dynamic>;
        mkskipped.add({
          'key': element['key']! as String,
          'public': element['public']! as String,
          'n': element['n']! as int,
        });
      }

      return OmemoDoubleRatchetWrapper(
        OmemoDoubleRatchet.fromJson(
          {
            ...ratchet,
            'acknowledged': intToBool(ratchet['acknowledged']! as int),
            'mkskipped': mkskipped,
          },
        ),
        ratchet['id']! as int,
        ratchet['jid']! as String,
      );
    }).toList();
  }

  Future<Map<RatchetMapKey, BTBVTrustState>> loadTrustCache() async {
    final entries = await _db.query(omemoTrustCacheTable);

    final mapEntries = entries.map<MapEntry<RatchetMapKey, BTBVTrustState>>((entry) {
      // TODO(PapaTutuWawa): Expose this from omemo_dart
      BTBVTrustState state;
      final value = entry['trust']! as int;
      if (value == 1) {
        state = BTBVTrustState.notTrusted;
      } else if (value == 2) {
        state = BTBVTrustState.blindTrust;
      } else if (value == 3) {
        state = BTBVTrustState.verified;
      } else {
        state = BTBVTrustState.notTrusted;
      }

      return MapEntry(
        RatchetMapKey.fromJsonKey(entry['key']! as String),
        state,
      );
    });

    return Map.fromEntries(mapEntries);
  }

  Future<void> saveTrustCache(Map<String, int> cache) async {
    final batch = _db.batch();

    // ignore: cascade_invocations
    batch.delete(omemoTrustCacheTable);
    for (final entry in cache.entries) {
      batch.insert(
        omemoTrustCacheTable,
        {
          'key': entry.key,
          'trust': entry.value,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit();
  }

  Future<Map<RatchetMapKey, bool>> loadTrustEnablementList() async {
    final entries = await _db.query(omemoTrustEnableListTable);

    final mapEntries = entries.map<MapEntry<RatchetMapKey, bool>>((entry) {
      return MapEntry(
        RatchetMapKey.fromJsonKey(entry['key']! as String),
        intToBool(entry['enabled']! as int),
      );
    });

    return Map.fromEntries(mapEntries);
  }

  Future<void> saveTrustEnablementList(Map<String, bool> list) async {
    final batch = _db.batch();

    // ignore: cascade_invocations
    batch.delete(omemoTrustEnableListTable);
    for (final entry in list.entries) {
      batch.insert(
        omemoTrustEnableListTable,
        {
          'key': entry.key,
          'enabled': boolToInt(entry.value),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }

    await batch.commit();
  }

  Future<Map<String, List<int>>> loadTrustDeviceList() async {
    final entries = await _db.query(omemoTrustDeviceListTable);

    final map = <String, List<int>>{};
    for (final entry in entries) {
      final key = entry['jid']! as String;
      final device = entry['device']! as int;

      if (map.containsKey(key)) {
        map[key]!.add(device);
      } else {
        map[key] = [device];
      }
    }

    return map;
  }

  Future<void> saveTrustDeviceList(Map<String, List<int>> list) async {
    final batch = _db.batch();

    // ignore: cascade_invocations
    batch.delete(omemoTrustDeviceListTable);
    for (final entry in list.entries) {
      for (final device in entry.value) {
        batch.insert(
          omemoTrustDeviceListTable,
          {
            'jid': entry.key,
            'device': device,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }

    await batch.commit();
  }

  Future<void> saveOmemoDevice(OmemoDevice device) async {
    await _db.insert(
      omemoDeviceTable,
      {
        'jid': device.jid,
        'id': device.id,
        'data': jsonEncode(await device.toJson()),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<OmemoDevice?> loadOmemoDevice(String jid) async {
    final data = await _db.query(
      omemoDeviceTable,
      where: 'jid = ?',
      whereArgs: [jid],
      limit: 1,
    );
    if (data.isEmpty) return null;

    final deviceJson = jsonDecode(data.first['data']! as String) as Map<String, dynamic>;
    // NOTE: We need to do this because Dart otherwise complains about not being able
    //       to cast dynamic to List<int>.
    final opks = List<Map<String, dynamic>>.empty(growable: true);
    final opksIter = deviceJson['opks']! as List<dynamic>;
    for (final _opk in opksIter) {
      final opk = _opk as Map<String, dynamic>;
      opks.add(<String, dynamic>{
        'id': opk['id']! as int,
        'public': opk['public']! as String,
        'private': opk['private']! as String,
      });
    }
    deviceJson['opks'] = opks;
    return OmemoDevice.fromJson(deviceJson);
  }

  Future<Map<String, List<int>>> loadOmemoDeviceList() async {
    final list = await _db.query(omemoDeviceListTable);
    final map = <String, List<int>>{};
    for (final entry in list) {
      final key = entry['jid']! as String;
      final id = entry['id']! as int;

      if (map.containsKey(key)) {
        map[key]!.add(id);
      } else {
        map[key] = [id];
      }
    }

    return map;
  }

  Future<void> saveOmemoDeviceList(Map<String, List<int>> list) async {
    final batch = _db.batch();

    // ignore: cascade_invocations
    batch.delete(omemoDeviceListTable);
    for (final entry in list.entries) {
      for (final id in entry.value) {
        batch.insert(
          omemoDeviceListTable,
          {
            'jid': entry.key,
            'id': id,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
    }

    await batch.commit();
  }

  Future<void> emptyOmemoSessionTables() async {
    final batch = _db.batch();

    // ignore: cascade_invocations
    batch
      ..delete(omemoRatchetsTable)
      ..delete(omemoTrustCacheTable)
      ..delete(omemoTrustEnableListTable);

    await batch.commit();
  }

  Future<void> addFingerprintsToCache(List<OmemoCacheTriple> items) async {
    final batch = _db.batch();
    for (final item in items) {
      batch.insert(
        omemoFingerprintCache,
        <String, dynamic>{
          'jid': item.jid,
          'id': item.deviceId,
          'fingerprint': item.fingerprint,
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit();
  }
  
  Future<List<OmemoCacheTriple>> getFingerprintsFromCache(String jid) async {
    final rawItems = await _db.query(
      omemoFingerprintCache,
      where: 'jid = ?',
      whereArgs: [jid],
    );

    return rawItems
      .map((item) {
        return OmemoCacheTriple(
          jid,
          item['id']! as int,
          item['fingerprint']! as String,
        );
      })
      .toList();
  }

  Future<Map<String, String>> getContactIds() async {
    return Map<String, String>.fromEntries(
      (await _db.query(contactsTable))
        .map((item) => MapEntry(
          item['jid']! as String,
          item['id']! as String,
        ),
      ),
    );
  }

  Future<void> addContactId(String id, String jid) async {
    await _db.insert(
      contactsTable,
      <String, String>{
        'id': id,
        'jid': jid,
      },
    );
  }

  Future<void> removeContactId(String id) async {
    await _db.delete(
      contactsTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<void> addStickerPackFromData(sticker_pack.StickerPack pack) async {
    await _db.insert(
      stickerPacksTable,
      pack.toDatabaseJson(),
    );
  }

  Future<sticker.Sticker> addStickerFromData(
    String mediaType,
    String desc,
    int size,
    int? width,
    int? height,
    Map<String, String> hashes,
    List<String> urlSources,
    String path,
    String stickerPackId,
    Map<String, String> suggests,
  ) async {
    final s = sticker.Sticker(
      getStickerHashKey(hashes),
      mediaType,
      desc,
      size,
      width,
      height,
      hashes,
      urlSources,
      path,
      stickerPackId,
      suggests,
    );

    await _db.insert(stickersTable, s.toDatabaseJson());
    return s;
  }

  Future<List<sticker_pack.StickerPack>> loadStickerPacks() async {
    final rawPacks = await _db.query(stickerPacksTable);
    final stickerPacks = List<sticker_pack.StickerPack>.empty(growable: true);
    for (final pack in rawPacks) {
      final rawStickers = await _db.query(
        stickersTable,
        where: 'stickerPackId = ?',
        whereArgs: [pack['id']! as String],
      );

      stickerPacks.add(
        sticker_pack.StickerPack.fromDatabaseJson(
          pack,
          rawStickers
            .map(sticker.Sticker.fromDatabaseJson)
            .toList(),
        ),
      );
    }

    return stickerPacks;
  }

  Future<void> removeStickerPackById(String id) async {
    await _db.delete(
      stickerPacksTable,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  Future<sticker_pack.StickerPack?> getStickerPackById(String id) async {
    final rawPack = await _db.query(
      stickerPacksTable,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (rawPack.isEmpty) return null;

    final rawStickers = await _db.query(
      stickersTable,
      where: 'stickerPackId = ?',
      whereArgs: [id],
    );

    return sticker_pack.StickerPack.fromDatabaseJson(
      rawPack.first,
      rawStickers
        .map(sticker.Sticker.fromDatabaseJson)
        .toList(),
    );
  }

  Future<void> addBlocklistEntry(String jid) async {
    await _db.insert(
      blocklistTable,
      {
        'jid': jid,
      },
    );
  }

  Future<void> removeBlocklistEntry(String jid) async {
    await _db.delete(
      blocklistTable,
      where: 'jid = ?',
      whereArgs: [jid],
    );
  }

  Future<void> removeAllBlocklistEntries() async {
    await _db.delete(
      blocklistTable,
    );
  }

  Future<List<String>> getBlocklistEntries() async {
    final result = await _db.query(blocklistTable);

    return result
      .map((m) => m['jid']! as String)
      .toList();
  }

  Future<List<String>> getSubscriptionRequests() async {
    return (await _db.query(subscriptionsTable))
      .map((m) => m['jid']! as String)
      .toList();
  }

  Future<void> addSubscriptionRequest(String jid) async {
    await _db.insert(
      subscriptionsTable,
      {
        'jid': jid,
      },
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<void> removeSubscriptionRequest(String jid) async {
    await _db.delete(
      subscriptionsTable,
      where: 'jid = ?',
      whereArgs: [jid],
    );
  }
}
