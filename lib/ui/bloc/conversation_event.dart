part of "conversation_bloc.dart";

abstract class ConversationEvent {}

/// Triggered when we first loaded the preferences
class InitConversationEvent extends ConversationEvent {
  final String backgroundPath;

  InitConversationEvent (this.backgroundPath);
}

/// Triggered when the content of the input field changed.
class MessageTextChangedEvent extends ConversationEvent {
  final String value;

  MessageTextChangedEvent(this.value);
}

/// Triggered a message is sent.
class MessageSentEvent extends ConversationEvent {
  MessageSentEvent();
}

/// Triggered before navigating to the [ConversationPage] to load the conversation
/// into the state. This event will also redirect accordingly.
class RequestedConversationEvent extends ConversationEvent {
  // These are placeholders in case we have to wait a bit longer
  final String jid;
  final String title;
  final String avatarUrl;

  RequestedConversationEvent(this.jid, this.title, this.avatarUrl);
}

/// Triggered by the UI when a message is quoted
class MessageQuotedEvent extends ConversationEvent {
  final Message message;

  MessageQuotedEvent(this.message);
}

/// Triggered by the UI when the quote should be removed
class QuoteRemovedEvent extends ConversationEvent {}

/// Triggered by the UI when a user should be blocked
class JidBlockedEvent extends ConversationEvent {
  final String jid;

  JidBlockedEvent(this.jid);
}

/// Triggered by the UI when a user should be added to the roster
class JidAddedEvent extends ConversationEvent {
  final String jid;

  JidAddedEvent(this.jid);
}

/// Triggered by the UI when we leave the conversation
class CurrentConversationResetEvent extends ConversationEvent {}

/// Triggered when we receive a message
class MessageAddedEvent extends ConversationEvent {
  final Message message;

  MessageAddedEvent(this.message);
}

/// Triggered when we updated a message
class MessageUpdatedEvent extends ConversationEvent {
  final Message message;

  MessageUpdatedEvent(this.message);
}
