import "package:moxxyv2/ui/redux/registration/state.dart";
import "package:moxxyv2/ui/redux/registration/actions.dart";

RegisterPageState registerReducer(RegisterPageState state, dynamic action) {
  if (action is NewProviderAction) {
    return state.copyWith(providerIndex: action.index);
  } else if (action is RegistrationSetErrorTextAction) {
    return state.copyWith(errorText: action.text);
  } else if (action is RegistrationResetErrorsAction) {
    return state.copyWith(errorText: null);
  }

  return state;
}
