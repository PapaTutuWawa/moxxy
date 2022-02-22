import "package:moxxyv2/shared/models/message.dart";
import "package:moxxyv2/shared/models/conversation.dart";
import "package:moxxyv2/xmpp/jid.dart";

/// Triggered when the send button should either be shown or replaced by the add button
/// (Refers to the conversation page)
class SetShowSendButtonAction {
  final bool show;

  SetShowSendButtonAction({ required this.show });
}

/// Triggered when the scroll-to-button button should appear or hide
class SetShowScrollToEndButtonAction {
  final bool show;

  SetShowScrollToEndButtonAction({ required this.show });
}

/// Triggered when a message has been sent
class SendMessageAction {
  final String body;
  final int timestamp;
  final String jid;

  SendMessageAction({ required this.body, required this.timestamp, required this.jid });
}

/// Triggered when a message has been received
class ReceiveMessageAction {
  final String body;
  final int timestamp;
  final JID from;
  final String jid;

  ReceiveMessageAction({ required this.from, required this.body, required this.timestamp, required this.jid });
}

/// Adds a single message to the UI
class AddMessageAction {
  final Message message;

  AddMessageAction({ required this.message });
}

/// Adds multiple [Message]s to the conversation with JID [conversationJid]
class AddMultipleMessagesAction {
  final String conversationJid;
  final List<Message> messages;
  final bool replace; // Replace whatever was in the state before for [conversationJid]

  AddMultipleMessagesAction({ required this.messages, required this.conversationJid, this.replace = true });
}

/// Triggered when a conversation should be marked as closed
class CloseConversationAction {
  final String jid;
  final int id;
  final bool redirect;

  CloseConversationAction({ required this.jid, required this.id, this.redirect = true });
}

/// Triggered when a conversation has been entered or left
class SetOpenConversationAction {
  final String? jid;

  SetOpenConversationAction({ this.jid });
}

/// Triggered from the UI only when a conversation should be created
class AddConversationFromUIAction {
  final String title;
  final String lastMessageBody;
  final String avatarUrl;
  final String jid;

  
  AddConversationFromUIAction({ required this.title, required this.lastMessageBody, required this.avatarUrl, required this.jid });
}

/// Triggered when a conversation should be added to the UI
class AddConversationAction {
  Conversation conversation;

  AddConversationAction({ required this.conversation });
}

/// Like [AddConversationAction] but bundles multiple conversations
class AddMultipleConversationsAction {
  List<Conversation> conversations;

  AddMultipleConversationsAction({ required this.conversations });
}

/// Triggered when the conversation with id [conversation.id] has been updated
class UpdateConversationAction {
  Conversation conversation;

  UpdateConversationAction({ required this.conversation });
}
