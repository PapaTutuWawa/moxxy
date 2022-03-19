part of "login_bloc.dart";

class LoginFormState {
  final bool isOkay;
  final String? error;

  const LoginFormState(this.isOkay, { this.error });
}

@freezed
class LoginState with _$LoginState {
  factory LoginState({
      @Default("") jid,
      @Default("") password,
      @Default(false) working,
      @Default(false) passwordVisible,
      @Default(LoginFormState(true)) jidState,
      @Default(LoginFormState(true)) passwordState
  }) = _LoginState;
}
