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

/// Triggered before navigating to the ConversationPage to load the conversation
/// into the state. This event will also redirect accordingly.
class RequestedConversationEvent extends ConversationEvent {
  RequestedConversationEvent(
    this.jid,
    this.title,
    this.avatarUrl, {
    this.removeUntilConversations = false,
    this.initialText,
    this.type = 'chat',
  });

  /// These are placeholders in case we have to wait a bit longer
  final String jid;
  final String title;
  final String avatarUrl;
  final bool removeUntilConversations;

  /// Initial value to put in the input field.
  final String? initialText;

  /// Type of the conversation
  final String type;
}

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

/// Triggered when we updated a conversation
class ConversationUpdatedEvent extends ConversationEvent {
  ConversationUpdatedEvent(this.conversation);
  final Conversation conversation;
}

/// Triggered when the user wants to pick images and videos for sending
class ImagePickerRequestedEvent extends ConversationEvent {}

/// Triggered when the user wants to pick generic files for sending
class FilePickerRequestedEvent extends ConversationEvent {}

/// Triggered when we enable or disable Omemo in the chat
class OmemoSetEvent extends ConversationEvent {
  OmemoSetEvent(this.enabled);
  final bool enabled;
}

/// Triggered when the dragging began
class SendButtonDragStartedEvent extends ConversationEvent {}

/// Triggered when the dragging ended
class SendButtonDragEndedEvent extends ConversationEvent {}

/// Triggered when the dragging ended
class SendButtonLockedEvent extends ConversationEvent {}

/// Triggered when the FAB has been locked
class SendButtonLockPressedEvent extends ConversationEvent {}

/// Triggered when the recording has been canceled
class RecordingCanceledEvent extends ConversationEvent {}
