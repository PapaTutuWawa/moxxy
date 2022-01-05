// TODO: "Send" the login data to perform the actual login
class PerformLoginAction {
  final String jid;
  final String password;

  PerformLoginAction({ required this.jid, required this.password });
}

// TODO: Merge
class LoginSetPasswordErrorAction {
  final String text;

  LoginSetPasswordErrorAction({ required this.text });
}
class LoginSetJidErrorAction {
  final String text;

  LoginSetJidErrorAction({ required this.text });
}
class LoginResetErrorsAction {}
// --- TODO END ---

class TogglePasswordVisibilityAction {}

class LoginSuccessfulAction {
  final String jid;
  final String displayName;

  LoginSuccessfulAction({ required this.jid, required this.displayName });
}

class LoginFailedAction {
  final String reason;

  LoginFailedAction({ required this.reason });
}
