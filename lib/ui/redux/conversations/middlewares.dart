import "package:moxxyv2/ui/redux/state.dart";
import "package:moxxyv2/ui/redux/conversation/actions.dart";

import "package:redux/redux.dart";

void conversationsMiddleware(Store<MoxxyState> store, action, NextDispatcher next) async {
  // TODO: I think this all has to go
  if (action is AddConversationFromUIAction) {
    // TODO: Notify the backend
  } else if (action is CloseConversationAction) {
    // TODO: Notify the backend
  }

  next(action);
}
