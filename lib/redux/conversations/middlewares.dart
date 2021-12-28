import "package:moxxyv2/redux/state.dart";
import "package:moxxyv2/redux/conversations/actions.dart";
import "package:moxxyv2/redux/conversation/actions.dart";
import "package:moxxyv2/repositories/conversation.dart";

import "package:redux/redux.dart";
import "package:get_it/get_it.dart";

void conversationsMiddleware(Store<MoxxyState> store, action, NextDispatcher next) {
  var repo = GetIt.I.get<DatabaseRepository>();

  if (action is AddConversationAction && !action.triggeredByDatabase) {
    if (repo.hasConversation(action.id)) {
      // TODO
    } else {
      repo.addConversationFromAction(action);
    }
  } else if (action is AddMessageAction) {
    if (repo.hasConversation(action.cid)) {
      repo.updateConversation(id: action.cid, lastMessageBody: action.body, lastChangeTimestamp: action.timestamp);
    } else {
      // TODO
    }

  }

  next(action);
}
