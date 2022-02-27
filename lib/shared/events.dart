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

const addToRosterResultType = "AddToRosterResult";
class AddToRosterResultEvent extends BaseIsolateEvent {
  final String result;
  final String? msg;
  final String? jid;

  AddToRosterResultEvent({ required this.result, this.msg, this.jid });
  AddToRosterResultEvent.fromJson(Map<String, dynamic> json) :
    result = json["result"]!,
    msg = json["msg"],
    jid = json["jid"] {
      assert(json["type"] == addToRosterResultType);
    }

  @override
  Map<String, dynamic> toJson() => {
    "type": addToRosterResultType,
    "result": result,
    "msg": msg,
    "jid": jid
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

const rosterItemAddedType = "RosterItemAddedEvent";
class RosterItemAddedEvent extends BaseIsolateEvent {
  final RosterItem item;

  RosterItemAddedEvent({ required this.item });
  RosterItemAddedEvent.fromJson(Map<String, dynamic> json) :
    item = RosterItem.fromJson(json["item"]!) {
      assert(json["type"] == rosterItemAddedType);
    }

  @override
  Map<String, dynamic> toJson() => {
    "type": rosterItemAddedType,
    "item": item.toJson()
  };
}

const conversationUpdatedType = "ConversationUpdatedEvent";
class ConversationUpdatedEvent extends BaseIsolateEvent {
  final Conversation conversation;

  ConversationUpdatedEvent({ required this.conversation });
  ConversationUpdatedEvent.fromJson(Map<String, dynamic> json) :
    conversation = Conversation.fromJson(json["conversation"]!) {
      assert(json["type"] == conversationUpdatedType);
    }

  @override
  Map<String, dynamic> toJson() => {
    "type": conversationUpdatedType,
    "conversation": conversation.toJson()
  };
}

const conversationCreatedType = "ConversationCreatedEvent";
class ConversationCreatedEvent extends BaseIsolateEvent {
  final Conversation conversation;

  ConversationCreatedEvent({ required this.conversation });
  ConversationCreatedEvent.fromJson(Map<String, dynamic> json) :
    conversation = Conversation.fromJson(json["conversation"]!) {
      assert(json["type"] == conversationCreatedType);
    }

  @override
  Map<String, dynamic> toJson() => {
    "type": conversationCreatedType,
    "conversation": conversation.toJson()
  };
}

const messageSendType = "MessageSendResult";
class MessageSendResultEvent extends BaseIsolateEvent {
  final Message message;

  MessageSendResultEvent({ required this.message });
  MessageSendResultEvent.fromJson(Map<String, dynamic> json) :
    message = Message.fromJson(json["message"]!) {
      assert(json["type"] == messageSendType);
    }

  @override
  Map<String, dynamic> toJson() => {
    "type": messageSendType,
    "message": message.toJson()
  };
}

const messageUpdatedType = "MessageUpdatedEvent";
class MessageUpdatedEvent extends BaseIsolateEvent {
  final Message message;

  MessageUpdatedEvent({ required this.message });
  MessageUpdatedEvent.fromJson(Map<String, dynamic> json) :
    message = Message.fromJson(json["message"]!) {
      assert(json["type"] == messageUpdatedType);
    }

  @override
  Map<String, dynamic> toJson() => {
    "type": messageUpdatedType, "message": message.toJson()
  };
}

const messageReceivedType = "MessageReceivedEvent";
class MessageReceivedEvent extends BaseIsolateEvent {
  final Message message;

  MessageReceivedEvent({ required this.message });
  MessageReceivedEvent.fromJson(Map<String, dynamic> json) :
    message = Message.fromJson(json["message"]!) {
      assert(json["type"] == messageReceivedType);
    }

  @override
  Map<String, dynamic> toJson() => {
    "type": messageReceivedType,
    "message": message.toJson()
  };
}

const connectionStateType = "ConnectionStateEvent";
class ConnectionStateEvent extends BaseIsolateEvent {
  final String state;

  ConnectionStateEvent({ required this.state });
  ConnectionStateEvent.fromJson(Map<String, dynamic> json) :
    state = json["state"]! {
      assert(json["type"] == connectionStateType);
    }

  @override
  Map<String, dynamic> toJson() => {
    "type": connectionStateType,
    "state": state
  };
}

const loginSuccessfulType = "LoginSuccessfulEvent";
class LoginSuccessfulEvent extends BaseIsolateEvent {
  final String displayName;
  final String jid;

  LoginSuccessfulEvent({ required this.displayName, required this.jid });
  LoginSuccessfulEvent.fromJson(Map<String, dynamic> json) :
    jid = json["jid"]!,
    displayName = json["displayName"]!
    {
      assert(json["type"] == loginSuccessfulType);
    }

  @override
  Map<String, dynamic> toJson() => {
    "type": loginSuccessfulType,
    "jid": jid,
    "displayName": displayName
  };
}

const loginFailedType = "LoginFailedEvent";
class LoginFailedEvent extends BaseIsolateEvent {
  final String reason;

  LoginFailedEvent({ required this.reason });
  LoginFailedEvent.fromJson(Map<String, dynamic> json) :
    reason = json["reason"]! {
      assert(json["type"] == loginFailedType);
    }

  @override
  Map<String, dynamic> toJson() => {
    "type": loginFailedType,
    "reason": reason
  };
}

const preStartResultType = "PreStartResult";
class PreStartResultEvent extends BaseIsolateEvent {
  final String state;
  final bool debugEnabled;
  final String? jid;
  final String? displayName;
  final String? avatarUrl;

  PreStartResultEvent({ required this.state, required this.debugEnabled, this.jid, this.displayName, this.avatarUrl });
  PreStartResultEvent.fromJson(Map<String, dynamic> json) :
    state = json["state"]!,
    debugEnabled = json["debugEnabled"]!,
    jid = json["jid"],
    displayName = json["displayName"],
    avatarUrl = json["avatarUrl"] {
      assert(json["type"] == preStartResultType);
    }

  @override
  Map<String, dynamic> toJson() => {
    "type": preStartResultType,
    "state": state,
    "debugEnabled": debugEnabled,
    "jid": jid,
    "displayName": displayName,
    "avatarUrl": avatarUrl
  };
}

const downloadProgressType = "DownloadProgressEvent";
class DownloadProgressEvent extends BaseIsolateEvent {
  final int id;
  final double progress;

  DownloadProgressEvent({ required this.id, required this.progress });
  DownloadProgressEvent.fromJson(Map<String, dynamic> json) :
    id = json["id"]!,
    // TODO: For some reason, this throws an exception if the progress is at 1.0
    // type 'int' is not a subtype of type 'double'
    progress = json["progress"]! {
      assert(json["type"] == downloadProgressType);
    }

  @override
  Map<String, dynamic> toJson() => {
    "type": downloadProgressType,
    "id": id,
    "progress": progress
  };
}
