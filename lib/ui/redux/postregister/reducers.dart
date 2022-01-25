import "package:moxxyv2/ui/redux/postregister/actions.dart";
import "package:moxxyv2/ui/redux/postregister/state.dart";

PostRegisterPageState postRegisterReducer(PostRegisterPageState state, dynamic action) {
  if (action is PostRegisterSetShowSnackbarAction) {
    return state.copyWith(showSnackbar: action.show);
  }

  return state;
}
