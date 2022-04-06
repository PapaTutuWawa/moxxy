part of "conversations_bloc.dart";

abstract class ConversationsEvent {}

/// Triggered when we got the first data
class ConversationsInitEvent extends ConversationsEvent {
  final String displayName;
  final String jid;
  final String? avatarUrl;
  final List<Conversation> conversations;

  ConversationsInitEvent(
    this.displayName,
    this.jid,
    this.conversations,
    {
      this.avatarUrl
    }
  );
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

/// Triggered when the avatar of the logged-in user has changed
class AvatarChangedEvent extends ConversationsEvent {
  final String path;

  AvatarChangedEvent(this.path);
}
