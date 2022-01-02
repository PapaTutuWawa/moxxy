import "dart:collection";

import "package:moxxyv2/models/conversation.dart";
import "package:moxxyv2/redux/conversations/actions.dart";
import "package:moxxyv2/redux/conversation/actions.dart";

List<Conversation> conversationReducer(List<Conversation> state, dynamic action) {
  if (action is AddConversationAction) {
    return state..add(action.conversation);
  } else if (action is AddMultipleConversationsAction) {
    return state..addAll(action.conversations);
  } else if (action is UpdateConversationAction) {
    return state.map((c) {
        if (c.id == action.conversation.id) {
          return action.conversation;
        }

        return c;
    }).toList();
  }
  
  return state;
}
