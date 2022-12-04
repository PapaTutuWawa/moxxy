part of 'addcontact_bloc.dart';

@freezed
class AddContactState with _$AddContactState {
  factory AddContactState({
      @Default('') String jid,
      @Default(null) String? jidError,
      @Default(false) bool isWorking,
  }) = _AddContactState;
}
