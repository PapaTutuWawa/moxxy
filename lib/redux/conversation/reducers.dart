import 'dart:collection';

import "package:moxxyv2/models/message.dart";
import "package:moxxyv2/redux/conversation/state.dart";
import "package:moxxyv2/redux/conversation/actions.dart";

HashMap<String, List<Message>> messageReducer(HashMap<String, List<Message>> state, dynamic action) {
  if (action is AddMessageAction) {
    if (!state.containsKey(action.message.from)) {
      state[action.message.from] = List.from([ action.message ]);
    } else {
      state[action.message.from] = state[action.message.from]!..add(action.message);
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
