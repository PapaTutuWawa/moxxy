part of 'joingroupchat_bloc.dart';

@freezed
class JoinGroupchatState with _$JoinGroupchatState {
  factory JoinGroupchatState({
    @Default('') String jid,
    @Default('') String nick,
    @Default(null) String? jidError,
    @Default(null) String? nickError,
    @Default(false) bool isWorking,
  }) = _JoinGroupchatState;
}
