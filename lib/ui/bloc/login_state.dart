part of 'login_bloc.dart';

class LoginFormState {

  const LoginFormState(this.isOkay, { this.error });
  final bool isOkay;
  final String? error;
}

@freezed
class LoginState with _$LoginState {
  factory LoginState({
    @Default('') String jid,
    @Default('') String password,
    @Default(false) bool working,
    @Default(false) bool passwordVisible,
    @Default(LoginFormState(true)) LoginFormState jidState,
    @Default(LoginFormState(true)) LoginFormState passwordState,
  }) = _LoginState;
}
