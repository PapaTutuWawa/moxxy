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
    // Our own JID
    @Default('') String jid,
    @Default('') String messageText,
    @Default(defaultSendButtonState) SendButtonState sendButtonState,
    @Default(null) Message? quotedMessage,
    @Default(null) Conversation? conversation,
    @Default('') String backgroundPath,
    @Default(false) bool pickerVisible,
    @Default(false) bool messageEditing,
    @Default('') String messageEditingOriginalBody,
    @Default(null) String? messageEditingSid,
    @Default(null) int? messageEditingId,

    // For recording
    @Default(false) bool isDragging,
    @Default(false) bool isLocked,
    @Default(false) bool isRecording,
  }) = _ConversationState;
}
