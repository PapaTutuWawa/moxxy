import 'dart:async';
import 'package:get_it/get_it.dart';
import 'package:logging/logging.dart';
import 'package:moxxyv2/service/database/creation.dart';
import 'package:moxxyv2/service/database/helpers.dart';
import 'package:moxxyv2/service/roster.dart';
import 'package:moxxyv2/shared/error_types.dart';
import 'package:moxxyv2/shared/models/conversation.dart';
import 'package:moxxyv2/shared/models/media.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/shared/models/roster.dart';
import 'package:moxxyv2/xmpp/xeps/xep_0085.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite_sqlcipher/sqflite.dart';

class DatabaseService {
  
  DatabaseService() : _log = Logger('DatabaseService');
  late Database _db;
  
  final Logger _log;

  Future<void> initialize() async {
    final dbPath = path.join(
      await getDatabasesPath(),
      'moxxy.db',
    );

    // TODO(PapaTutuWawa): Set a password and use it
    _db = await openDatabase(
      dbPath,
      version: 1,
      onCreate: createDatabase,
      onConfigure: configureDatabase,
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
      final id = c['id']! as int;

      final sharedMediaRaw = await _db.query(
        'SharedMedia',
        where: 'conversation_id = ?',
        whereArgs: [id],
        orderBy: 'timestamp DESC',
      );
      final rosterItem = await GetIt.I.get<RosterService>()
        .getRosterItemByJid(c['jid']! as String);

      tmp.add(
        Conversation.fromDatabaseJson(
          c,
          rosterItem != null,
          rosterItem?.subscription ?? 'none',
          sharedMediaRaw,
        ),
      );
    }

    _log.finest(tmp.toString());
    
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
          whereArgs: [jid, m['id']! as int],
        )).first;
        quotes = Message.fromDatabaseJson(rawQuote, null);
      }

      messages.add(Message.fromDatabaseJson(m, quotes));
    }

    return messages;
  }
  
  /// Updates the conversation with id [id] inside the database.
  Future<Conversation> updateConversation(int id, {
      String? lastMessageBody,
      int? lastChangeTimestamp,
      bool? open,
      int? unreadCounter,
      String? avatarUrl,
      List<SharedMedium>? sharedMedia,
      ChatState? chatState,
      bool? muted,
    }
  ) async {
    final cd = (await _db.query(
      'Conversations',
      where: 'id = ?',
      whereArgs: [id],
    )).first;
    final c = Map<String, dynamic>.from(cd);

    //await c.sharedMedia.load();
    if (lastMessageBody != null) {
      c['lastMessageBody'] = lastMessageBody;
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
    if (sharedMedia != null) {
      // TODO(PapaTutuWawa): Implement
      //c.sharedMedia.addAll(sharedMedia);
    }
    if (muted != null) {
      c['muted'] = muted;
    }

    await _db.update(
      'Conversations',
      c,
      where: 'id = ?',
      whereArgs: [id],
    );

    final rosterItem = await GetIt.I.get<RosterService>().getRosterItemByJid(c['jid']! as String);
    return Conversation.fromDatabaseJson(
      c,
      rosterItem != null,
      rosterItem?.subscription ?? 'none',
      // TODO(PapaTutuWawa): Implement
      <Map<String, dynamic>>[],
    );
  }

  /// Creates a [Conversation] inside the database given the data. This is so that the
  /// [Conversation] object can carry its database id.
  Future<Conversation> addConversationFromData(
    String title,
    String lastMessageBody,
    String avatarUrl,
    String jid,
    int unreadCounter,
    int lastChangeTimestamp,
    List<SharedMedium> sharedMedia,
    bool open,
    bool muted,
  ) async {
    final rosterItem = await GetIt.I.get<RosterService>().getRosterItemByJid(jid);
    final conversation = Conversation(
      title,
      lastMessageBody,
      avatarUrl,
      jid,
      unreadCounter,
      lastChangeTimestamp,
      sharedMedia,
      -1,
      open,
      rosterItem != null,
      rosterItem?.subscription ?? 'none',
      muted,
      ChatState.gone,
    );

    // TODO(PapaTutuWawa): Handle shared media
    //c.sharedMedia.addAll(sharedMedia);

    return conversation.copyWith(
      id: await _db.insert('Conversations', conversation.toDatabaseJson()),
    );
  }

  /// Like [addConversationFromData] but for [SharedMedium].
  Future<SharedMedium> addSharedMediumFromData(String path, int timestamp, { String? mime }) async {
    final s = SharedMedium(
      -1,
      path,
      timestamp,
      mime: mime,
    );

    return s.copyWith(
      id: await _db.insert('SharedMedia', s.toDatabaseJson()),
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
    {
      String? srcUrl,
      String? mediaUrl,
      String? mediaType,
      String? thumbnailData,
      String? thumbnailDimensions,
      String? originId,
      String? quoteId,
      String? filename,
    }
  ) async {
    final m = Message(
      sender,
      body,
      timestamp,
      sid,
      -1,
      conversationJid,
      isMedia,
      isFileUploadNotification,
      errorType: noError,
      mediaUrl: mediaUrl,
      mediaType: mediaType,
      thumbnailData: thumbnailData,
      thumbnailDimensions: thumbnailDimensions,
      srcUrl: srcUrl,
      received: false,
      displayed: false,
      acked: false,
      originId: originId,
      filename: filename,
    );

    Message? quotes;
    if (quoteId != null) {
      quotes = await getMessageByXmppId(quoteId, conversationJid);
      if (quotes == null) {
        _log.warning('Failed to add quote for message with id $quoteId');
      }
    }

    return m.copyWith(
      id: await _db.insert('Messages', m.toDatabaseJson(quotes?.id)),
      quotes: quotes,
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
  
  /// Updates the message item with id [id] inside the database.
  Future<Message> updateMessage(int id, {
    String? mediaUrl,
    String? mediaType,
    bool? received,
    bool? displayed,
    bool? acked,
    int? errorType,
    bool? isFileUploadNotification,
    String? srcUrl,
  }) async {
    final md = (await _db.query(
      'Messages',
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    )).first;
    final m = Map<String, dynamic>.from(md);

    if (mediaUrl != null) {
      m['mediaUrl'] = mediaUrl;
    }
    if (mediaType != null) {
      m['mediaType'] = mediaType;
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
    if (errorType != null) {
      m['errorType'] = errorType;
    }
    if (isFileUploadNotification != null) {
      m['isFileUploadNotification'] = boolToInt(isFileUploadNotification);
    }
    if (srcUrl != null) {
      m['srcUrl'] = srcUrl;
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
      <String>[],
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
      List<String>? groups,
    }
  ) async {
    final id_ = (await _db.query(
      'RosterItems',
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

    await _db.update(
      'RosterItems',
      i,
      where: 'id = ?',
      whereArgs: [id],
    );
    return RosterItem.fromDatabaseJson(i);
  }
}
