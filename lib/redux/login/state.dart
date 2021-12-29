class LoginPageState {
  final bool showPassword;
  final String? passwordError;
  final String? jidError;

  LoginPageState({ required this.showPassword, this.passwordError, this.jidError });

  LoginPageState copyWith({ bool? showPassword, String? passwordError, String? jidError }) {
    return LoginPageState(
      showPassword: showPassword ?? this.showPassword,
      passwordError: passwordError,
      jidError: jidError
    );
  }
}
