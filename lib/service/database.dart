import "dart:collection";
import "dart:async";

import "package:moxxyv2/shared/helpers.dart";
import "package:moxxyv2/shared/events.dart";
import "package:moxxyv2/shared/models/conversation.dart";
import "package:moxxyv2/shared/models/message.dart";
import "package:moxxyv2/shared/models/roster.dart";
import "package:moxxyv2/service/service.dart";
import "package:moxxyv2/service/db/conversation.dart";
import "package:moxxyv2/service/db/message.dart";
import "package:moxxyv2/service/db/roster.dart";

import "package:isar/isar.dart";
import "package:logging/logging.dart";

Conversation conversationDbToModel(DBConversation c, bool inRoster) {
  return Conversation(
    c.title,
    c.lastMessageBody,
    c.avatarUrl,
    c.jid,
    c.unreadCounter,
    c.lastChangeTimestamp,
    c.sharedMediaPaths,
    c.id!,
    c.open,
    inRoster
  );
}

RosterItem rosterDbToModel(DBRosterItem i) {
  return RosterItem(
    id: i.id!,
    avatarUrl: i.avatarUrl,
    jid: i.jid,
    title: i.title
  );
}

Message messageDbToModel(DBMessage m) {
  return Message(
    m.from,
    m.body,
    m.timestamp,
    m.sent,
    m.sid,
    m.id!,
    m.conversationJid,
    m.isMedia,
    originId: m.originId,
    received: m.received,
    displayed: m.displayed,
    acked: m.acked,
    mediaUrl: m.mediaUrl,
    mediaType: m.mediaType,
    thumbnailData: m.thumbnailData,
    thumbnailDimensions: m.thumbnailDimensions,
    srcUrl: m.srcUrl,
    quotes: m.quotes.value != null ? messageDbToModel(m.quotes.value!) : null
  );
}

class DatabaseService {
  final Isar isar;

  final HashMap<int, Conversation> _conversationCache = HashMap();
  final HashMap<String, List<Message>> _messageCache = HashMap();
  final HashMap<String, RosterItem> _rosterCache = HashMap();
  final List<String> loadedConversations = List.empty(growable: true);

  bool _rosterLoaded;
  
  final Logger _log;
  
  DatabaseService(this.isar) : _rosterLoaded = false, _log = Logger("DatabaseService");

  /// Returns the database ID of the conversation with jid [jid] or null if not found.
  Future<Conversation?> getConversationByJid(String jid) async {
    // TODO: Check if we already tried to load once
    if (_conversationCache.isEmpty) {
      await loadConversations();
    }

    return firstWhereOrNull(
      // TODO: Maybe have it accept an iterable
      _conversationCache.values.toList(),
      (Conversation c) => c.jid == jid
    );
  }
  
  /// Loads all conversations from the database and adds them to the state and cache.
  Future<List<Conversation>> loadConversations() async {
    final conversationsRaw = await isar.dBConversations.where().findAll();

    final tmp = List<Conversation>.empty(growable: true);
    for (final c in conversationsRaw) {
      final conv = conversationDbToModel(
        c,
        await isInRoster(c.jid)
      );
      tmp.add(conv);
       _conversationCache[conv.id] = conv;
    }

    return tmp;
  }

  /// Loads all messages for the conversation with jid [jid].
  Future<void> loadMessagesForJid(String jid) async {
    if (loadedConversations.contains(jid)) {
      // TODO
      /*
      sendData(LoadMessagesForJidEvent(
          jid: jid, messages: _messageCache[jid]!
      ));
      */
     
      return;
    }

    final messages = await isar.dBMessages.where().conversationJidEqualTo(jid).findAll();
    loadedConversations.add(jid);

    if (!_messageCache.containsKey(jid)) {
      _messageCache[jid] = List.empty(growable: true);
    }

    final List<Message> tmp = List.empty(growable: true);
    for (final m in messages) {
      await m.quotes.load();

      final msg = messageDbToModel(m);
      _messageCache[jid]!.add(msg);
      tmp.add(msg);
    }

    // TODO
    /*
    sendData(LoadMessagesForJidEvent(
        jid: jid,
        messages: tmp
    ));
    */
  }

  /// Updates the conversation with id [id] inside the database.
  Future<Conversation> updateConversation({ required int id, String? lastMessageBody, int? lastChangeTimestamp, bool? open, int? unreadCounter, String? avatarUrl, List<String>? sharedMediaPaths }) async {
    final c = (await isar.dBConversations.get(id))!;
    if (lastMessageBody != null) {
      c.lastMessageBody = lastMessageBody;
    }
    if (lastChangeTimestamp != null) {
      c.lastChangeTimestamp = lastChangeTimestamp;
    }
    if (open != null) {
      c.open = open;
    }
    if (unreadCounter != null) {
      c.unreadCounter = unreadCounter;
    }
    if (avatarUrl != null) {
      c.avatarUrl = avatarUrl;
    }
    if (sharedMediaPaths != null) {
      c.sharedMediaPaths = sharedMediaPaths;
    }

    await isar.writeTxn((isar) async {
        await isar.dBConversations.put(c);
    });

    final conversation = conversationDbToModel(c, await isInRoster(c.jid));
    _conversationCache[c.id!] = conversation;
    return conversation;
  }

  /// Creates a [Conversation] inside the database given the data. This is so that the
  /// [Conversation] object can carry its database id.
  Future<Conversation> addConversationFromData(String title, String lastMessageBody, String avatarUrl, String jid, int unreadCounter, int lastChangeTimestamp, List<String> sharedMediaPaths, bool open) async {
    final c = DBConversation()
      ..jid = jid
      ..title = title
      ..avatarUrl = avatarUrl
      ..lastChangeTimestamp = lastChangeTimestamp
      ..unreadCounter = unreadCounter
      ..lastMessageBody = lastMessageBody
      ..sharedMediaPaths = sharedMediaPaths
      ..open = open;

    await isar.writeTxn((isar) async {
        await isar.dBConversations.put(c);
    }); 

    final conversation = conversationDbToModel(c, await isInRoster(c.jid)); 
    _conversationCache[c.id!] = conversation;

    return conversation;
  }

  /// Same as [addConversationFromData] but for a [Message].
  Future<Message> addMessageFromData(
    String body,
    int timestamp,
    String from,
    String conversationJid,
    bool sent,
    bool isMedia,
    String sid,
    {
      String? srcUrl,
      String? mediaUrl,
      String? thumbnailData,
      String? thumbnailDimensions,
      String? originId,
      String? quoteId
    }
  ) async {
    final m = DBMessage()
      ..from = from
      ..conversationJid = conversationJid
      ..timestamp = timestamp
      ..body = body
      ..sent = sent
      ..isMedia = isMedia
      ..srcUrl = srcUrl
      ..sid = sid
      ..thumbnailData = thumbnailData
      ..thumbnailDimensions = thumbnailDimensions
      ..received = false
      ..displayed = false
      ..acked = false
      ..originId = originId;

    if (quoteId != null) {
      final quotes = await getMessageByXmppId(quoteId, conversationJid);
      if (quotes != null) {
        m.quotes.value = quotes;
      } else {
        _log.warning("Failed to add quote for message with id $quoteId");
      }
    }

    await isar.writeTxn((isar) async {
        await isar.dBMessages.put(m);
    });

    final msg = messageDbToModel(m);
    if (_messageCache.containsKey(conversationJid)) {
      _messageCache[conversationJid]!.add(msg);
    }

    return msg;
  }

  Future<DBMessage?> getMessageByXmppId(String id, String conversationJid) async {
    return await isar.dBMessages.filter()
      .conversationJidEqualTo(conversationJid)
      .and()
      .group((q) => q
        .sidEqualTo(id)
        .or()
        .originIdEqualTo(id)
      ).findFirst();
  }
  
  /// Updates the message item with id [id] inside the database.
  Future<Message> updateMessage({ required int id, String? mediaUrl, String? mediaType, bool? received, bool? displayed, bool? acked }) async {
    final i = (await isar.dBMessages.get(id))!;
    if (mediaUrl != null) {
      i.mediaUrl = mediaUrl;
    }
    if (mediaType != null) {
      i.mediaType = mediaType;
    }
    if (received != null) {
      i.received = received;
    }
    if (displayed != null) {
      i.displayed = displayed;
    }
    if (acked != null) {
      i.acked = acked;
    }

    await isar.writeTxn((isar) async {
        await isar.dBMessages.put(i);
    });

    final msg = messageDbToModel(i);

    // Update cache
    if (_messageCache.containsKey(msg.conversationJid)) {
      _messageCache[msg.conversationJid] = _messageCache[msg.conversationJid]!.map((m) {
          if (m.id == msg.id) return msg;

          return m;
      }).toList();
    }
    
    return msg;
  }
  
  /// Loads roster items from the database
  Future<List<RosterItem>> loadRosterItems() async {
    final roster = await isar.dBRosterItems.where().findAll();
    final items = roster.map((item) => rosterDbToModel(item));

    _rosterCache.clear();
    for (var item in items) {
      _rosterCache[item.jid] = item;
    }

    _log.finest("Roster loaded: $items");
    _rosterLoaded = true;
    return items.toList();
  }

  /// Removes a roster item from the database and cache
  Future<void> removeRosterItemByJid(String jid, { bool nullOkay = false }) async {
    final item = _rosterCache[jid];
    
    if (item != null) {
      await isar.writeTxn((isar) async {
          await isar.dBRosterItems.delete(item.id);
      });
      _rosterCache.remove(jid);
    } else if (!nullOkay) {
      _log.severe("removeFromRoster: Could not find $jid in roster state");
    }
  }

  /// Create a roster item from data
  Future<RosterItem> addRosterItemFromData(String avatarUrl, String jid, String title, { List<String>? groups }) async {
    final rosterItem = DBRosterItem()
      ..jid = jid
      ..title = title
      ..avatarUrl = avatarUrl
      ..groups = groups ?? const [];

    await isar.writeTxn((isar) async {
        await isar.dBRosterItems.put(rosterItem);
    });

    final item = rosterDbToModel(rosterItem);

    _rosterCache[item.jid] = item;
    return item;
  }

  /// Updates the roster item with id [id] inside the database.
  Future<RosterItem> updateRosterItem({ required int id, String? avatarUrl, String? title, List<String>? groups }) async {
    final i = (await isar.dBRosterItems.get(id))!;
    if (avatarUrl != null) {
      i.avatarUrl = avatarUrl;
    }
    if (title != null) {
      i.title = title;
    }
    if (groups != null) {
      i.groups = groups;
    }

    await isar.writeTxn((isar) async {
        await isar.dBRosterItems.put(i);
    });

    final item = rosterDbToModel(i);
    _rosterCache[item.jid] = item;
    return item;
  }
  
  /// Returns true if a roster item with jid [jid] exists
  Future<bool> isInRoster(String jid) async {
    if (!_rosterLoaded) {
      await loadRosterItems();
    }

    return _rosterCache.containsKey(jid);
  }

  /// Returns true if a roster item with jid [jid] exists
  Future<List<RosterItem>> getRoster() async {
    if (!_rosterLoaded) {
      await loadRosterItems();
    }

    return _rosterCache.values.toList();
  }
  
  /// Returns the roster item if it exists
  Future<RosterItem?> getRosterItemByJid(String jid) async {
    if (await isInRoster(jid)) {
      return _rosterCache[jid];
    }

    return null;
  }

  bool isRosterLoaded() => _rosterLoaded;
}
