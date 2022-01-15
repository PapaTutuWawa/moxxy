import "dart:async";
import "package:moxxyv2/redux/state.dart";
import "package:moxxyv2/redux/global/actions.dart";
import "package:moxxyv2/redux/addcontact/actions.dart";
import "package:moxxyv2/repositories/roster.dart";
import "package:moxxyv2/repositories/xmpp.dart";
import "package:moxxyv2/redux/roster/actions.dart";
import "package:moxxyv2/redux/roster/actions.dart";
import "package:moxxyv2/xmpp/connection.dart";
import "package:moxxyv2/db/roster.dart" as db;

import "package:redux/redux.dart";
import "package:get_it/get_it.dart";
import "package:flutter_redux_navigation/flutter_redux_navigation.dart";
import "package:flutter_background_service/flutter_background_service.dart";

void rosterMiddleware(Store<MoxxyState> store, action, NextDispatcher next) {
  if (action is RemoveRosterItemUIAction) {
    FlutterBackgroundService().sendData({
        "type": "RemoveRosterItemAction",
        "jid": action.jid
    });
  }

  next(action);
}
