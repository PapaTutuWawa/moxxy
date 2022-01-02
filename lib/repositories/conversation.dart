import "dart:collection";

import "package:moxxyv2/db/conversation.dart";
import "package:moxxyv2/db/message.dart";
import "package:moxxyv2/models/conversation.dart";
import "package:moxxyv2/models/message.dart";
import "package:moxxyv2/redux/state.dart";
import "package:moxxyv2/redux/conversations/actions.dart";
import "package:moxxyv2/redux/conversation/actions.dart";

import "package:isar/isar.dart";
import "package:redux/redux.dart";

import "package:moxxyv2/isar.g.dart";

// TODO: Either rename this ConversationRepository or put all the database stuff here and
//       rename the file to database.dart
class DatabaseRepository {
  final Isar isar;
  final Store<MoxxyState> store;

  final HashMap<int, DBConversation> _cache = HashMap();
  final List<String> loadedConversations = List.empty(growable: true);
  
  DatabaseRepository({ required this.isar, required this.store });
 
  Future<void> loadConversations() async {
    var conversations = await this.isar.dBConversations.where().findAll();

    // TODO: Optimise by creating an action that just sets them all at once
    conversations.forEach((c) {
        this._cache[c.id!] = c;
        this.store.dispatch(AddConversationAction(
            conversation: Conversation(
            id: c.id!,
            title: c.title,
            jid: c.jid,
            avatarUrl: c.avatarUrl,
            lastMessageBody: c.lastMessageBody,
            unreadCounter: c.unreadCounter,
            lastChangeTimestamp: c.lastChangeTimestamp,
            sharedMediaPaths: [],
            open: c.open
          )
        ));
      }
    );
  }

  Future<void> loadMessagesForJid(String jid) async {
    final messages = await this.isar.dBMessages.where().conversationJidEqualTo(jid).findAll();
    this.loadedConversations.add(jid);

    // TODO: Optimise by creating an action that just sets them all at once
    messages.forEach((m) => this.store.dispatch(AddMessageAction(message: Message(
            from: m.from,
            conversationJid: m.conversationJid,
            body: m.body,
            timestamp: m.timestamp,
            sent: m.sent,
            id: m.id!
    ))));
  }
  
  // TODO
  bool hasConversation(int id) {
    return this._cache.containsKey(id);
  }

  Future<void> updateConversation({ required int id, String? lastMessageBody, int? lastChangeTimestamp, bool? open, int? unreadCounter }) async {
    print("updateConversation");

    final c = this._cache[id]!;
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
  }

  Future<Conversation> addConversationFromData(String title, String lastMessageBody, String avatarUrl, String jid, int unreadCounter, int lastChangeTimestamp, List<String> sharedMediaPaths, bool open) async {
    print("addConversationFromAction");
    final c = DBConversation()
      ..jid = jid
      ..title = title
      ..avatarUrl = avatarUrl
      ..lastChangeTimestamp = lastChangeTimestamp
      ..unreadCounter = unreadCounter
      ..lastMessageBody = lastMessageBody
      ..open = open;
    await this.isar.writeTxn((isar) async {
        await isar.dBConversations.put(c);
        print("DONE");
    });
    this._cache[c.id!] = c;

    return Conversation(
      title: title,
      lastMessageBody: lastMessageBody,
      avatarUrl: avatarUrl,
      jid: jid,
      id: c.id!,
      unreadCounter: unreadCounter,
      lastChangeTimestamp: lastChangeTimestamp,
      sharedMediaPaths: sharedMediaPaths,
      open: open
    );
  }

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
