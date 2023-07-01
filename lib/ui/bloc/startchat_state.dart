part of 'startchat_bloc.dart';

@freezed
class StartChatState with _$StartChatState {
  factory StartChatState({
    @Default('') String jid,
    @Default(null) String? jidError,
    @Default(false) bool isWorking,
  }) = _StartChatState;
}
