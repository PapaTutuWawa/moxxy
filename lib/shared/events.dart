import "package:moxxyv2/shared/models/roster.dart";
import "package:moxxyv2/shared/models/conversation.dart";
import "package:moxxyv2/shared/models/message.dart";

abstract class BaseIsolateEvent {
  Map<String, dynamic> toJson();
  //BaseIsolateEvent fromJson(Map<String, dynamic> json);
}

const rosterDiffType = "RosterDiff";
class RosterDiffEvent extends BaseIsolateEvent {
  final List<RosterItem> newItems;
  final List<RosterItem> changedItems;
  final List<String> removedItems;

  RosterDiffEvent({ this.newItems = const [], this.changedItems = const [], this.removedItems = const [] });
  RosterDiffEvent.fromJson(Map<String, dynamic> json) :
    newItems = List<RosterItem>.from(json["newItems"]!.map((i) => RosterItem.fromJson(i))),
    changedItems = List<RosterItem>.from(json["changedItems"]!.map((i) => RosterItem.fromJson(i))),
    removedItems = List<String>.from(json["removedItems"]!) {
      assert(json["type"] == rosterDiffType);
    }

  @override
  Map<String, dynamic> toJson() => {
    "type": rosterDiffType,
    "newItems": newItems.map((i) => i.toJson()).toList(),
    "changedItems": changedItems.map((i) => i.toJson()).toList(),
    "removedItems": removedItems
  };
}

const loadConversationsResultType = "LoadConversationsResult";
class LoadConversationsResultEvent extends BaseIsolateEvent {
  final List<Conversation> conversations;

  LoadConversationsResultEvent({ required this.conversations });
  LoadConversationsResultEvent.fromJson(Map<String, dynamic> json) :
    conversations = List<Conversation>.from(json["conversations"]!.map((i) => Conversation.fromJson(i))) {
      assert(json["type"] == loadConversationsResultType);
    }

  @override
  Map<String, dynamic> toJson() => {
    "type": loadConversationsResultType,
    "conversations": conversations.map((c) => c.toJson()).toList()
  };
}

const loadMessagesForJidType = "LoadMessagesForJidResult";
class LoadMessagesForJidEvent extends BaseIsolateEvent {
  final List<Message> messages;
  final String jid;

  LoadMessagesForJidEvent({ required this.jid, required this.messages });
  LoadMessagesForJidEvent.fromJson(Map<String, dynamic> json) :
    jid = json["jid"]!,
    messages = List<Message>.from(json["messages"]!.map((m) => Message.fromJson(m))) {
      assert(json["type"] == loadMessagesForJidType);
    }

  @override
  Map<String, dynamic> toJson() => {
    "type": loadMessagesForJidType,
    "jid": jid,
    "messages": messages.map((m) => m.toJson()).toList()
  };
}
