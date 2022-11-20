part of 'conversation_bloc.dart';

abstract class ConversationEvent {}

/// Triggered when we first loaded the preferences
class InitConversationEvent extends ConversationEvent {

  InitConversationEvent(this.backgroundPath);
  final String backgroundPath;
}

/// Triggered when the background image changed
class BackgroundChangedEvent extends ConversationEvent {

  BackgroundChangedEvent(this.backgroundPath);
  final String backgroundPath;
}

/// Triggered when the content of the input field changed.
class MessageTextChangedEvent extends ConversationEvent {

  MessageTextChangedEvent(this.value);
  final String value;
}

/// Triggered a message is sent.
class MessageSentEvent extends ConversationEvent {
  MessageSentEvent();
}

/// Triggered before navigating to the ConversationPage to load the conversation
/// into the state. This event will also redirect accordingly.
class RequestedConversationEvent extends ConversationEvent {

  RequestedConversationEvent(
    this.jid,
    this.title,
    this.avatarUrl,
    {
      this.removeUntilConversations = false,
    }
  );
  // These are placeholders in case we have to wait a bit longer
  final String jid;
  final String title;
  final String avatarUrl;
  final bool removeUntilConversations;
}

/// Triggered by the UI when a message is quoted
class MessageQuotedEvent extends ConversationEvent {

  MessageQuotedEvent(this.message);
  final Message message;
}

/// Triggered by the UI when the quote should be removed
class QuoteRemovedEvent extends ConversationEvent {}

/// Triggered by the UI when a user should be blocked
class JidBlockedEvent extends ConversationEvent {

  JidBlockedEvent(this.jid);
  final String jid;
}

/// Triggered by the UI when a user should be added to the roster
class JidAddedEvent extends ConversationEvent {

  JidAddedEvent(this.jid);
  final String jid;
}

/// Triggered by the UI when we leave the conversation
class CurrentConversationResetEvent extends ConversationEvent {}

/// Triggered when we receive a message
class MessageAddedEvent extends ConversationEvent {

  MessageAddedEvent(this.message);
  final Message message;
}

/// Triggered when we updated a message
class MessageUpdatedEvent extends ConversationEvent {

  MessageUpdatedEvent(this.message);
  final Message message;
}

/// Triggered when we updated a conversation
class ConversationUpdatedEvent extends ConversationEvent {

  ConversationUpdatedEvent(this.conversation);
  final Conversation conversation;
}

/// Triggered when the app is left, either by the screen locking or the user switching apps
class AppStateChanged extends ConversationEvent {

  AppStateChanged(this.open);
  final bool open;
}

/// Triggered when the user wants to pick images and videos for sending
class ImagePickerRequestedEvent extends ConversationEvent {}

/// Triggered when the user wants to pick generic files for sending
class FilePickerRequestedEvent extends ConversationEvent {}

/// Triggered when the emoji button is pressed
class EmojiPickerToggledEvent extends ConversationEvent {
  EmojiPickerToggledEvent({this.handleKeyboard = true});
  final bool handleKeyboard;
}

/// Triggered when we received our own JID
class OwnJidReceivedEvent extends ConversationEvent {
  OwnJidReceivedEvent(this.jid);
  final String jid;
}

/// Triggered when we enable or disable Omemo in the chat
class OmemoSetEvent extends ConversationEvent {
  OmemoSetEvent(this.enabled);
  final bool enabled;
}

/// Triggered when a message should be retracted
class MessageRetractedEvent extends ConversationEvent {
  MessageRetractedEvent(this.id);
  final String id;
}
