import "dart:collection";
import "dart:async";

import "package:moxxyv2/helpers.dart";
import "package:moxxyv2/db/conversation.dart";
import "package:moxxyv2/db/message.dart";
import "package:moxxyv2/db/roster.dart";
import "package:moxxyv2/models/conversation.dart";
import "package:moxxyv2/models/message.dart";
import "package:moxxyv2/models/roster.dart";
import "package:moxxyv2/redux/state.dart";
import "package:moxxyv2/redux/conversation/actions.dart";

import "package:isar/isar.dart";
import "package:redux/redux.dart";

import "package:moxxyv2/isar.g.dart";

Conversation conversationDbToModel(DBConversation c) {
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

RosterItem rosterDbToModel(DBRosterItem i) {
  return RosterItem(
    id: i.id!,
    avatarUrl: i.avatarUrl,
    jid: i.jid,
    title: i.title
  );
}

class DatabaseRepository {
  final Isar isar;

  final HashMap<int, Conversation> _conversationCache = HashMap();
  final HashMap<String, List<Message>> _messageCache = HashMap();
  final HashMap<String, RosterItem> _rosterCache = HashMap();
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
    final conversations = conversationsRaw.map((c) => conversationDbToModel(c));
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

    final conversation = conversationDbToModel(c);
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

    final conversation = conversationDbToModel(c); 
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

  /// Loads roster items from the database
  Future<void> loadRosterItems({ bool notify = true }) async {
    final roster = await this.isar.dBRosterItems.where().findAll();
    final items = roster.map((item) => rosterDbToModel(item));
    this._rosterCache.clear();
    items.forEach((item) => this._rosterCache[item.jid] = item);

    if (notify) {
      this.sendData({
          "type": "LoadRosterItemsResult",
          "items": items.map((i) => i.toJson()).toList()
      });
    }
  }

  /// Removes a roster item from the database and cache
  Future<void> removeRosterItemByJid(String jid, { bool nullOkay = false }) async {
    final item = this._rosterCache[jid];
    
    if (item != null) {
      await this.isar.writeTxn((isar) async {
          await isar.dBRosterItems.delete(item.id);
      });
      this._rosterCache.remove(jid);
    } else if (!nullOkay) {
      print("RosterRepository::removeFromRoster: Could not find $jid in roster state");
    }
  }
  
  /// Create a roster item from data
  Future<RosterItem> addRosterItemFromData(String avatarUrl, String jid, String title) async {
    final rosterItem = DBRosterItem()
      ..jid = jid
      ..title = title
      ..avatarUrl = avatarUrl;

    await this.isar.writeTxn((isar) async {
        await isar.dBRosterItems.put(rosterItem);
        print("DONE");
    });

    final item = rosterDbToModel(rosterItem);

    this._rosterCache[item.jid] = item;
    return item;
  }

  /// Returns true if a roster item with jid [jid] exists
  Future<bool> isInRoster(String jid) async {
    // TODO: Check if we already loaded it once
    if (this._rosterCache.isEmpty) {
      await this.loadRosterItems(notify: false);
    }

    return this._rosterCache.containsKey(jid);
  }

  /// Returns the roster item if it exists
  Future<RosterItem?> getRosterItemByJid(String jid) async {
    if (await this.isInRoster(jid)) {
      return this._rosterCache[jid];
    }

    return null;
  }
}
