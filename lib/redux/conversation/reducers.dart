import 'dart:collection';

import "package:moxxyv2/models/message.dart";
import "package:moxxyv2/redux/conversation/state.dart";
import "package:moxxyv2/redux/conversation/actions.dart";

HashMap<String, List<Message>> messageReducer(HashMap<String, List<Message>> state, dynamic action) {
  if (action is AddMessageAction) {
    if (!state.containsKey(action.message.conversationJid)) {
      state[action.message.conversationJid] = List.from([ action.message ]);
    } else {
      state[action.message.conversationJid] = state[action.message.conversationJid]!..add(action.message);
    }

    return state;
  }

  return state;
}

ConversationPageState conversationPageReducer(ConversationPageState state, dynamic action) {
  if (action is SetShowSendButtonAction) {
    return state.copyWith(showSendButton: action.show);
  } else if (action is SetShowScrollToEndButtonAction) {
    return state.copyWith(showScrollToEndButton: action.show);
  }

  return state;
}
