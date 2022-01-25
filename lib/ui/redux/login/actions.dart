/// Triggered when a login is to be performed.
class PerformLoginAction {
  final String jid;
  final String password;

  PerformLoginAction({ required this.jid, required this.password });
}

/// Triggered when an error message should be displayed on the login page.
///
/// [passwordError] is the error message displayed below the password input. If set to null,
/// then no message is displayed.
/// Same for [jidError] with the difference that it is displayed below the JID entry.
class LoginSetErrorAction {
  final String? passwordError;
  final String? jidError;

  LoginSetErrorAction ({ this.passwordError, this.jidError });
}

/// Triggered when the password visibility on the login page is to be toggled.
class TogglePasswordVisibilityAction {}

/// Triggered by the backend when the login has been successful.
class LoginSuccessfulAction {
  final String jid;
  final String displayName;

  LoginSuccessfulAction({ required this.jid, required this.displayName });
}

/// Triggered by the backend when the login has failed.
class LoginFailedAction {
  final String reason;

  LoginFailedAction({ required this.reason });
}
