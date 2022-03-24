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
