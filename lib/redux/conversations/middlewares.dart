import "package:moxxyv2/redux/state.dart";
import "package:moxxyv2/redux/conversations/actions.dart";
import "package:moxxyv2/redux/conversation/actions.dart";
import "package:moxxyv2/repositories/conversation.dart";
import "package:moxxyv2/models/conversation.dart";

import "package:redux/redux.dart";
import "package:flutter_redux_navigation/flutter_redux_navigation.dart";
import "package:get_it/get_it.dart";

void conversationsMiddleware(Store<MoxxyState> store, action, NextDispatcher next) async {
  
  next(action);
}
