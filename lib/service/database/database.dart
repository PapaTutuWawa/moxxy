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

    _log.finest('Conversations: ${conversationsRaw.length}');
    
    final tmp = List<Conversation>.empty(growable: true);
    for (final c in conversationsRaw) {
      final id = c['id']! as int;

      final sharedMediaRaw = await _db.query(
        'SharedMedia',
        where: 'conversation_id = ?',
        whereArgs: [id],
        orderBy: 'timestamp DESC',
      );
      final sharedMedia = sharedMediaRaw
        .map(SharedMedium.fromJson)
        .toList();
      final rosterItem = await GetIt.I.get<RosterService>()
        .getRosterItemByJid(c['jid']! as String);

      tmp.add(
        Conversation.fromJson({
          ...c,
          'muted': intToBool(c['muted']! as int),
          'open': intToBool(c['open']! as int),
          'sharedMedia': sharedMedia,
          'inRoster': rosterItem != null,
          'subscription': rosterItem?.subscription ?? 'none',
          'chatState': ConversationChatStateConverter().toJson(ChatState.gone),
        }),
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
      orderBy: 'timestamp DESC',
    );

    final messages = List<Message>.empty(growable: true);
    for (final m in rawMessages) {
      Message? quotes;
      if (m['quote_id'] != null) {
        final rawQuote = await _db.query(
          'Messages',
          where: 'conversationJid = ?, id = ?',
          whereArgs: [jid, m['id']! as int],
        );
        quotes = Message.fromJson(rawQuote.first);
      }

      messages.add(
        Message.fromJson({
          ...m,
          'quotes': quotes,
          'received': intToBool(m['received']! as int),
          'displayed': intToBool(m['displayed']! as int),
          'acked': intToBool(m['acked']! as int),
          'isMedia': intToBool(m['isMedia']! as int),
          'isFileUploadNotification': intToBool(m['isFileUploadNotification']! as int),
        }),
      );
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
    return Conversation.fromJson({
      ...c,
      'muted': intToBool(c['muted']! as int),
      'open': intToBool(c['open']! as int),
      // TODO(PapaTutuWawa): Implement
      'sharedMedia': <SharedMedium>[],
      'inRoster': rosterItem != null,
      'subscription': rosterItem?.subscription ?? 'none',
      'chatState': ConversationChatStateConverter().toJson(ChatState.gone),
    });
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

    final map = conversation
      .toJson()
      ..remove('id')
      ..remove('chatState')
      ..remove('sharedMedia')
      ..remove('inRoster')
      ..remove('subscription');
    return conversation.copyWith(
      id: await _db.insert(
        'Conversations',
        {
          ...map,
          'open': boolToInt(conversation.open),
          'muted': boolToInt(conversation.muted),
        },
      ),
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

    final map = s
      .toJson()
      ..remove('id');
    return s.copyWith(
      id: await _db.insert(
        'SharedMedia',
        map,
      ),
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

    // TODO(PapaTutuWawa): Handle quotes
    /*
    if (quoteId != null) {
      final quotes = await getMessageByXmppId(quoteId, conversationJid);
      if (quotes != null) {
        m.quotes.value = quotes;
      } else {
        _log.warning('Failed to add quote for message with id $quoteId');
      }
    }
    */

    final map = m
      .toJson()
      ..remove('id')
      ..remove('quotes')
      ..remove('isDownloading')
      ..remove('isUploading');

    Message? quotes;
    if (quoteId != null) {
      quotes = await getMessageByXmppId(quoteId, conversationJid);
      if (quotes != null) {
        map['quote_id'] = quoteId;
      } else {
        _log.warning('Failed to add quote for message with id $quoteId');
      }
    }

    return m.copyWith(
      id: await _db.insert(
        'Messages',
        {
          ...map,

          'isMedia': boolToInt(m.isMedia),
          'isFileUploadNotification': boolToInt(m.isFileUploadNotification),
          'received': boolToInt(m.received),
          'displayed': boolToInt(m.displayed),
          'acked': boolToInt(m.acked),
        },
      ),
      quotes: quotes,
    );
  }

  Future<Message?> getMessageByXmppId(String id, String conversationJid) async {
    _log.finest('id: $id, conversationJid: $conversationJid');
    final messagesRaw = await _db.query(
      'Messages',
      where: 'conversationJid = ? AND (sid = ? or originId = ?)',
      whereArgs: [conversationJid, id, id],
      limit: 1,
    );

    if (messagesRaw.isEmpty) return null;

    // TODO(PapaTutuWawa): Load the quoted message
    final msg = messagesRaw.first;
    return Message.fromJson({
      ...msg,
      'isMedia': intToBool(msg['isMedia']! as int),
      'isFileUploadNotification': intToBool(msg['isFileUploadNotification']! as int),
      'received': intToBool(msg['received']! as int),
      'displayed': intToBool(msg['displayed']! as int),
      'acked': intToBool(msg['acked']! as int),
    });
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
    
    return Message.fromJson({
      ...m,
      'isMedia': intToBool(m['isMedia']! as int),
      'isFileUploadNotification': intToBool(m['isFileUploadNotification']! as int),
      'received': intToBool(m['received']! as int),
      'displayed': intToBool(m['displayed']! as int),
      'acked': intToBool(m['acked']! as int),
    });
  }
  
  /// Loads roster items from the database
  Future<List<RosterItem>> loadRosterItems() async {
    final items = await _db.query('RosterItems');

    return items.map((item) {
      item['groups'] = <String>[];
      return RosterItem.fromJson(item);
    }).toList();
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

    final map = i
      .toJson()
      ..remove('id');
    
    return i.copyWith(
      id: await _db.insert(
        'RosterItems',
        map,
      ),
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
    return RosterItem.fromJson(i);
  }
}
