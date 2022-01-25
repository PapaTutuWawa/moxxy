import "package:moxxyv2/ui/redux/addcontact/actions.dart";

String? addContactErrorTextReducer(String? state, dynamic action) {
  if (action is AddContactSetErrorLogin) {
    return action.errorText;
  }

  return state;
}
