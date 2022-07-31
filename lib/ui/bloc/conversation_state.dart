part of 'conversation_bloc.dart';

@freezed
class ConversationState with _$ConversationState {
  factory ConversationState({
    @Default('') String messageText,
    @Default(false) bool showSendButton,
    @Default(null) Message? quotedMessage,
    @Default(<Message>[]) List<Message> messages,
    @Default(null) Conversation? conversation,
    @Default('') String backgroundPath,
    @Default(true) bool scrolledToBottom,
  }) = _ConversationState;
}
