part of 'conversation_bloc.dart';

@freezed
class ConversationState with _$ConversationState {
  factory ConversationState({
    // Our own JID
    @Default('') String jid,
    @Default('') String messageText,
    @Default(false) bool showSendButton,
    @Default(null) Message? quotedMessage,
    @Default(<Message>[]) List<Message> messages,
    @Default(null) Conversation? conversation,
    @Default('') String backgroundPath,
    @Default(false) bool emojiPickerVisible,
    @Default(false) bool messageEditing,
    @Default('') String messageEditingOriginalBody,
    @Default(null) String? messageEditingSid,
    @Default(null) int? messageEditingId,
  }) = _ConversationState;
}
