part of "conversations_bloc.dart";

abstract class ConversationsEvent {}

/// Triggered when we got the first data
class ConversationsInitEvent extends ConversationsEvent {
  final String displayName;
  final String jid;
  final List<Conversation> conversations;

  ConversationsInitEvent(this.displayName, this.jid, this.conversations);
}

/// Triggered when a conversation has been added.
class ConversationsAddedEvent extends ConversationsEvent {
  final Conversation conversation;

  ConversationsAddedEvent(this.conversation);
}

/// Triggered when a conversation got updated
class ConversationsUpdatedEvent extends ConversationsEvent {
  final Conversation conversation;

  ConversationsUpdatedEvent(this.conversation);
}
