part of 'startgroupchat_bloc.dart';

@freezed
class StartGroupchatState with _$StartGroupchatState {
  factory StartGroupchatState({
    @Default('') String jid,
    @Default('') String nick,
    @Default(null) String? jidError,
    @Default(null) String? nickError,
    @Default(false) bool isWorking,
  }) = _StartGroupchatState;
}
