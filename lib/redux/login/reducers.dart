import "package:moxxyv2/redux/login/actions.dart";
import "package:moxxyv2/redux/login/state.dart";

LoginPageState loginReducer(LoginPageState state, dynamic action) {
  if (action is TogglePasswordVisibilityAction) {
    return state.copyWith(showPassword: !state.showPassword);
  } else if (action is LoginSetErrorAction) {
    return state.copyWith(passwordError: action.passwordError, jidError: action.jidError, loginError: null);
  } else if (action is LoginFailedAction) {
    return state.copyWith(
      loginError: action.reason
    );
  } else if (action is PerformLoginAction) {
    return state.copyWith(
      showPassword: false
    );
  }

  return state;
}
