part of 'conversation_bloc.dart';

enum SendButtonState {
  audio,
  send,
  cancelCorrection,
}
const defaultSendButtonState = SendButtonState.audio;

@freezed
class ConversationState with _$ConversationState {
  factory ConversationState({
    // Our own JID
    @Default('') String jid,
    @Default('') String messageText,
    @Default(defaultSendButtonState) SendButtonState sendButtonState,
    @Default(null) Message? quotedMessage,
    @Default(<Message>[]) List<Message> messages,
    @Default(null) Conversation? conversation,
    @Default('') String backgroundPath,
    @Default(false) bool emojiPickerVisible,
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
