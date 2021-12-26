class LoginPageState {
  final bool doingWork;
  final bool showPassword;
  final String? passwordError;
  final String? jidError;

  LoginPageState({ required this.doingWork, required this.showPassword, this.passwordError, this.jidError });

  LoginPageState copyWith({ bool? doingWork, bool? showPassword, String? passwordError, String? jidError }) {
    return LoginPageState(
      doingWork: doingWork ?? this.doingWork,
      showPassword: showPassword ?? this.showPassword,
      passwordError: passwordError,
      jidError: jidError
    );
  }
}
