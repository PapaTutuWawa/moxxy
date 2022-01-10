import "package:moxxyv2/redux/addcontact/actions.dart";

String? addContactErrorTextReducer(String? state, dynamic action) {
  if (action is AddContactSetErrorLogin) {
    return action.errorText;
  }

  return state;
}
