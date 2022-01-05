import "package:moxxyv2/redux/login/actions.dart";
import "package:moxxyv2/redux/login/state.dart";

LoginPageState loginReducer(LoginPageState state, dynamic action) {
  if (action is TogglePasswordVisibilityAction) {
    return state.copyWith(showPassword: !state.showPassword);
  } else if (action is LoginSetPasswordErrorAction) {
    return state.copyWith(passwordError: action.text);
  } else if (action is LoginSetJidErrorAction) {
    return state.copyWith(jidError: action.text);
  } else if (action is LoginResetErrorsAction) {
    return state.copyWith(
      passwordError: null,
      jidError: null,
      loginError: null
    );
  } else if (action is LoginFailedAction) {
    return state.copyWith(
      loginError: action.reason
    );
  }

  return state;
}
