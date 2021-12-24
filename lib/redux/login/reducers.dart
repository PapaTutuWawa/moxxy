import "package:moxxyv2/redux/login/actions.dart";
import "package:moxxyv2/ui/pages/login/state.dart";

LoginPageState loginReducer(LoginPageState state, dynamic action) {
  if (action is PerformLoginAction) {
    return state.copyWith(doingWork: true);
  } else if (action is TogglePasswordVisibilityAction) {
    return state.copyWith(showPassword: !state.showPassword);
  }

  return state;
}
