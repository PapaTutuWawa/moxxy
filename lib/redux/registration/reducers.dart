import "package:moxxyv2/ui/pages/register/state.dart";
import "package:moxxyv2/redux/registration/actions.dart";

RegisterPageState registerReducer(RegisterPageState state, dynamic action) {
  if (action is NewProviderAction) {
    return state.copyWith(providerIndex: action.index);
  } else if (action is PerformRegistrationAction) {
    return state.copyWith(doingWork: true);
  } else if (action is RegistrationSetErrorTextAction) {
    return state.copyWith(errorText: action.text);
  } else if (action is RegistrationResetErrorsAction) {
    return state.copyWith(errorText: null);
  }

  return state;
}
