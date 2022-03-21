part of "conversations_bloc.dart";

@freezed
class ConversationsState with _$ConversationsState {
  factory ConversationsState({
      @Default([]) List<Conversation> conversations,
      @Default("") displayName,
      @Default("") avatarUrl
  }) = _ConversationsState;
}
