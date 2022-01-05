class LoginPageState {
  final bool showPassword;
  final String? passwordError;
  final String? jidError;
  final String? loginError;

  LoginPageState({ required this.showPassword, this.passwordError, this.jidError, this.loginError });
  LoginPageState.initialState() : showPassword = false, passwordError = null, jidError = null, loginError = null;

  LoginPageState copyWith({ bool? showPassword, String? passwordError, String? jidError, String? loginError }) {
    return LoginPageState(
      showPassword: showPassword ?? this.showPassword,
      passwordError: passwordError,
      jidError: jidError,
      loginError: loginError
    );
  }
}
