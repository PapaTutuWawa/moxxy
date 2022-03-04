import "package:moxxyv2/shared/commands.dart";
import "package:moxxyv2/ui/redux/state.dart";
import "package:moxxyv2/ui/redux/preferences/actions.dart";

import "package:redux/redux.dart";
import "package:flutter_background_service/flutter_background_service.dart";

void preferencesMiddleware(Store<MoxxyState> store, action, NextDispatcher next) {
  if (action is SetPreferencesAction) {
    FlutterBackgroundService().sendData(
      SetPreferencesCommand(preferences: action.preferences).toJson()
    );
  }
  
  next(action);
}
