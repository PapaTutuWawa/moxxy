part of 'conversation_bloc.dart';

enum SendButtonState {
  /// Open the speed dial when tapped.
  multi,

  /// Send the current message when tapped.
  send,

  /// Send the currently recorded voice message,
  sendVoiceMessage,

  /// Cancel the current correction when tapped.
  cancelCorrection,
}

const defaultSendButtonState = SendButtonState.multi;

@freezed
class ConversationState with _$ConversationState {
  factory ConversationState({
    @Default(null) Conversation? conversation,
    @Default('') String backgroundPath,

    // For recording
    @Default(false) bool isDragging,
    @Default(false) bool isLocked,
    @Default(false) bool isRecording,
  }) = _ConversationState;
}
