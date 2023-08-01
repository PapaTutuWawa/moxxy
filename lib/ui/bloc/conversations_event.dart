part of 'conversations_bloc.dart';

abstract class ConversationsEvent {}

/// Triggered when we got the first data
class ConversationsInitEvent extends ConversationsEvent {
  ConversationsInitEvent(
    this.displayName,
    this.jid,
    this.conversations, {
    this.avatarUrl,
  });
  final String displayName;
  final String jid;
  final String? avatarUrl;
  final List<Conversation> conversations;
}

/// Triggered when a conversation has been added.
class ConversationsAddedEvent extends ConversationsEvent {
  ConversationsAddedEvent(this.conversation);
  final Conversation conversation;
}

/// Triggered when a conversation got updated
class ConversationsUpdatedEvent extends ConversationsEvent {
  ConversationsUpdatedEvent(this.conversation);
  final Conversation conversation;
}

/// Triggered when the avatar of the logged-in user has changed
class AvatarChangedEvent extends ConversationsEvent {
  AvatarChangedEvent(this.path);
  final String path;
}

/// Triggered by the UI when a conversation has been closed
class ConversationClosedEvent extends ConversationsEvent {
  ConversationClosedEvent(this.jid);
  final String jid;
}

/// Triggered by the UI when a conversation has been marked as read, i.e.
/// its unreadCounter should be set to zero
class ConversationMarkedAsReadEvent extends ConversationsEvent {
  ConversationMarkedAsReadEvent(this.jid);
  final String jid;
}

/// Triggered by the UI when we received a fresh list of conversations, for example
/// after removing old media files.
class ConversationsSetEvent extends ConversationsEvent {
  ConversationsSetEvent(this.conversations);
  final List<Conversation> conversations;
}
