import "package:moxxyv2/ui/redux/state.dart";
import "package:moxxyv2/ui/redux/start/actions.dart";

import "package:redux/redux.dart";

void startMiddleware(Store<MoxxyState> store, action, NextDispatcher next) {
  if (action is PerformPrestartAction) {
    // TODO: Notify the backend that the UI just started
  }
  
  next(action);
}
