import "package:moxxyv2/ui/constants.dart";
import "package:moxxyv2/ui/redux/state.dart";
import "package:moxxyv2/ui/redux/account/actions.dart";
import "package:moxxyv2/shared/commands.dart" as commands;

import "package:redux/redux.dart";
import "package:flutter_redux_navigation/flutter_redux_navigation.dart";
import "package:flutter_background_service/flutter_background_service.dart";

void accountMiddleware(Store<MoxxyState> store, action, NextDispatcher next) {
  if (action is SetDisplayNameAction) {
    // TODO: Tell [XmppRepository]
  } else if (action is SetAvatarAction) {
    FlutterBackgroundService().sendData(
      commands.SetAvatarCommand(
        path: action.avatarUrl
      ).toJson()
    );
  } else if (action is PerformLogoutAction) {
    // TODO: Tell [XmppRepository]
    store.dispatch(NavigateToAction.replace(introRoute));
  }

  next(action);
}
