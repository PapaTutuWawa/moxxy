// TODO: "Send" the login data to perform the actual login
class PerformLoginAction {
  final String jid;

  PerformLoginAction({ required this.jid });
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
  final String streamResumptionToken;

  LoginSuccessfulAction({ required this.jid, required this.displayName, required this.streamResumptionToken });
}
