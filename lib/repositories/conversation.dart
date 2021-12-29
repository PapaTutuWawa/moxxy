import "dart:collection";

import "package:moxxyv2/db/conversation.dart" as db;
import "package:moxxyv2/models/conversation.dart" as model;
import "package:moxxyv2/redux/state.dart";
import "package:moxxyv2/redux/conversations/actions.dart";

import "package:isar/isar.dart";
import "package:redux/redux.dart";

import "package:moxxyv2/isar.g.dart";

// TODO: Either rename this ConversationRepository or put all the database stuff here and
//       rename the file to database.dart
class DatabaseRepository {
  final Isar isar;
  final Store<MoxxyState> store;

  final HashMap<int, db.Conversation> _cache = HashMap();
  
  DatabaseRepository({ required this.isar, required this.store });

  Future<void> loadConversations() async {
    var conversations = await this.isar.conversations.where().findAll();

    conversations.forEach((c) {
        this._cache[c.id!] = c;
        this.store.dispatch(AddConversationAction(
            id: c.id!,
            title: c.title,
            jid: c.jid,
            avatarUrl: c.avatarUrl,
            lastMessageBody: c.lastMessageBody,
            unreadCounter: c.unreadCounter,
            lastChangeTimestamp: c.lastChangeTimestamp,
            sharedMediaPaths: [],
            open: c.open,
            triggeredByDatabase: true
        ));
      }
    );
  }

  // TODO
  bool hasConversation(int id) {
    return this._cache.containsKey(id);
  }

  Future<void> updateConversation({ required int id, String? lastMessageBody, int? lastChangeTimestamp, bool? open }) async {
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

    await this.isar.writeTxn((isar) async {
        await isar.conversations.put(c);
        print("DONE");
    });
  }
  
  Future<void> addConversationFromAction(AddConversationAction action) async {
    print("addConversationFromACtion");
    final c = db.Conversation()
      ..jid = action.jid
      ..title = action.title
      ..avatarUrl = action.avatarUrl
      ..lastChangeTimestamp = action.lastChangeTimestamp
      ..unreadCounter = action.unreadCounter
      ..lastMessageBody = action.lastMessageBody
      ..open = action.open;
    await this.isar.writeTxn((isar) async {
        await isar.conversations.put(c);
        print("DONE");
    });
  }
  
  Future<void> addConversation(model.Conversation conversation) async {
    final c = db.Conversation()
      ..jid = conversation.jid
      ..title = conversation.title
      ..avatarUrl = conversation.avatarUrl
      ..lastChangeTimestamp = conversation.lastChangeTimestamp
      ..unreadCounter = conversation.unreadCounter
      ..lastMessageBody = conversation.lastMessageBody
      ..open = conversation.open;
    await this.isar.writeTxn((isar) async {
        await isar.conversations.put(c);
    });
  }
}
