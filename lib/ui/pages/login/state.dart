class LoginPageState {
  final bool doingWork;
  final bool showPassword;

  LoginPageState({ required this.doingWork, required this.showPassword });

  LoginPageState copyWith({ bool? doingWork, bool? showPassword }) {
    return LoginPageState(
      doingWork: doingWork ?? this.doingWork,
      showPassword: showPassword ?? this.showPassword
    );
  }
}
