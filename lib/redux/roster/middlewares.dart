import "dart:async";
import "package:moxxyv2/redux/state.dart";
import "package:moxxyv2/redux/global/actions.dart";
import "package:moxxyv2/redux/addcontact/actions.dart";
import "package:moxxyv2/repositories/roster.dart";
import "package:moxxyv2/repositories/xmpp.dart";
import "package:moxxyv2/redux/roster/actions.dart";
import "package:moxxyv2/redux/roster/actions.dart";
import "package:moxxyv2/db/roster.dart" as db;

import "package:redux/redux.dart";
import "package:get_it/get_it.dart";
import "package:flutter_redux_navigation/flutter_redux_navigation.dart";

// TODO: Add an action for when we're done
void rosterMiddleware(Store<MoxxyState> store, action, NextDispatcher next) {
  if (action is AddRosterItemAction && !action.triggeredByDatabase) {
    GetIt.I.get<RosterRepository>().addRosterItemFromData(action.avatarUrl, action.jid, action.title);
  } else if (action is SaveCurrentRosterVersionAction) {
    GetIt.I.get<XmppRepository>().saveLastRosterVersion(action.ver);
  }

  next(action);
}
