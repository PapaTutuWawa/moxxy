// TODO: "Send" the login data to perform the actual login
class PerformLoginAction {}

class LoginSetPasswordErrorAction {
  final String text;

  LoginSetPasswordErrorAction({ required this.text });
}

class LoginSetJidErrorAction {
  final String text;

  LoginSetJidErrorAction({ required this.text });
}

class LoginResetErrorsAction {}

// TODO:
class LoginSuccessfulAction {}

class TogglePasswordVisibilityAction {}
