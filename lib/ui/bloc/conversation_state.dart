part of 'conversation_bloc.dart';

enum SendButtonState {
  multi,
  send,
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
