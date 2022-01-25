import "package:moxxyv2/ui/redux/profile/actions.dart";
import "package:moxxyv2/ui/redux/profile/state.dart";

ProfilePageState profileReducer(ProfilePageState state, dynamic action) {
  if (action is ProfileSetShowSnackbarAction) {
    return state.copyWith(showSnackbar: action.show);
  }

  return state;
}
