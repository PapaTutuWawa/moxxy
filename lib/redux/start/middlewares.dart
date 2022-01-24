import "package:moxxyv2/redux/state.dart";
import "package:moxxyv2/redux/start/actions.dart";

import "package:redux/redux.dart";

void startMiddleware(Store<MoxxyState> store, action, NextDispatcher next) {
  if (action is PerformPrestartAction) {
    // TODO: Notify the backend that the UI just started
  }
  
  next(action);
}
