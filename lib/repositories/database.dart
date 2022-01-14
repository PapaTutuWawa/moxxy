import "dart:collection";
import "dart:async";

import "package:moxxyv2/helpers.dart";
import "package:moxxyv2/db/conversation.dart";
import "package:moxxyv2/db/message.dart";
import "package:moxxyv2/db/roster.dart";
import "package:moxxyv2/models/conversation.dart";
import "package:moxxyv2/models/message.dart";
import "package:moxxyv2/redux/state.dart";
import "package:moxxyv2/redux/conversation/actions.dart";

import "package:isar/isar.dart";
import "package:redux/redux.dart";

import "package:moxxyv2/isar.g.dart";

Conversation dbToModel(DBConversation c) {
  return Conversation(
    id: c.id!,
    title: c.title,
    jid: c.jid,
    avatarUrl: c.avatarUrl,
    lastMessageBody: c.lastMessageBody,
    unreadCounter: c.unreadCounter,
    lastChangeTimestamp: c.lastChangeTimestamp,
    sharedMediaPaths: [],
    open: c.open
  );
}

class DatabaseRepository {
  final Isar isar;

  final HashMap<int, Conversation> _conversationCache = HashMap();
  final HashMap<String, List<Message>> _messageCache = HashMap();
  final List<String> loadedConversations = List.empty(growable: true);

  final void Function(Map<String, dynamic>) sendData;
  
  DatabaseRepository({ required this.isar, required this.sendData });

  /// Returns the database ID of the conversation with jid [jid] or null if not found.
  Future<Conversation?> getConversationByJid(String jid) async {
    // TODO: Check if we already tried to load once
    if (this._conversationCache.isEmpty) {
      await this.loadConversations(notify: false);
    }

    return firstWhereOrNull(
      // TODO: Maybe have it accept an iterable
      this._conversationCache.values.toList(),
      (Conversation c) => c.jid == jid
    );
  }
  
  /// Loads all conversations from the database and adds them to the state and cache.
  Future<void> loadConversations({ bool notify = true }) async {
    final conversationsRaw = await this.isar.dBConversations.where().findAll();
    final conversations = conversationsRaw.map((c) => dbToModel(c));
    conversations.forEach((c) {
        this._conversationCache[c.id] = c;
    });

    if (notify) {
      this.sendData({
          "type": "LoadConversationsResult",
          "conversations": conversations.map((c) => c.toJson()).toList()
      });
    }
  }

  /// Loads all messages for the conversation with jid [jid].
  Future<void> loadMessagesForJid(String jid) async {
    final messages = await this.isar.dBMessages.where().conversationJidEqualTo(jid).findAll();
    this.loadedConversations.add(jid);

    if (!this._messageCache.containsKey(jid)) {
      this._messageCache[jid] = List.empty(growable: true);
    }
    
    this.sendData({
        "type": "LoadMessagesForJidResult",
        "jid": jid,
        "messages": messages.map((m) {
            final message = Message(
              from: m.from,
              conversationJid: m.conversationJid,
              body: m.body,
              timestamp: m.timestamp,
              sent: m.sent,
              id: m.id!
            );
            this._messageCache[jid]!.add(message);
            return message.toJson();
        }).toList()
    });
  }

  /// Updates the conversation with id [id] inside the database.
  Future<Conversation> updateConversation({ required int id, String? lastMessageBody, int? lastChangeTimestamp, bool? open, int? unreadCounter }) async {
    print("updateConversation");

    final c = (await this.isar.dBConversations.get(id))!;
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

    await this.isar.writeTxn((isar) async {
        await isar.dBConversations.put(c);
        print("DONE");
    });

    final conversation = dbToModel(c);
    this._conversationCache[c.id!] = conversation;
    return conversation;
  }

  /// Creates a [Conversation] inside the database given the data. This is so that the
  /// [Conversation] object can carry its database id.
  Future<Conversation> addConversationFromData(String title, String lastMessageBody, String avatarUrl, String jid, int unreadCounter, int lastChangeTimestamp, List<String> sharedMediaPaths, bool open) async {
    print("addConversationFromAction");
    final c = DBConversation()
      ..jid = jid
      ..title = title
      ..avatarUrl = avatarUrl
      ..lastChangeTimestamp = lastChangeTimestamp
      ..unreadCounter = unreadCounter
      ..lastMessageBody = lastMessageBody
      ..sharedMediaPaths = sharedMediaPaths
      ..open = open;

    await this.isar.writeTxn((isar) async {
        await isar.dBConversations.put(c);
        print("DONE");
    }); 

    final conversation = dbToModel(c); 
    this._conversationCache[c.id!] = conversation;

    return conversation;
  }

  /// Same as [this.addConversationFromData] but for a [Message].
  Future<Message> addMessageFromData(String body, int timestamp, String from, String conversationJid, bool sent) async {
    print("addMessageFromData");
    final m = DBMessage()
      ..from = from
      ..conversationJid = conversationJid
      ..timestamp = timestamp
      ..body = body
      ..sent = sent;
      
    await this.isar.writeTxn((isar) async {
        await isar.dBMessages.put(m);
        print("DONE");
    });

    return Message(
      body: body,
      from: from,
      conversationJid: conversationJid,
      timestamp: timestamp,
      sent: sent,
      id: m.id!
    );
  }
}
