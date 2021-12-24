import "package:moxxyv2/ui/pages/addcontact/state.dart";
import "package:moxxyv2/redux/addcontact/actions.dart";

AddContactPageState addContactPageReducer(AddContactPageState state, dynamic action) {
  if (action is AddContactAction) {
    return state.copyWith(doingWork: true);
  }

  return state;
}
