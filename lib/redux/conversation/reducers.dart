import 'dart:collection';

import "package:moxxyv2/models/message.dart";
import "package:moxxyv2/ui/pages/conversation/state.dart";
import "package:moxxyv2/redux/conversation/actions.dart";

HashMap<String, List<Message>> messageReducer(HashMap<String, List<Message>> state, dynamic action) {
  if (action is AddMessageAction) {
    HashMap<String, List<Message>> map = HashMap<String, List<Message>>()..addAll(state);

    Message msg = Message(
      from: action.from,
      body: action.body,
      timestamp: action.timestamp,
      sent: true
    );
    
    String jid = action.jid;
    if (!map.containsKey(jid)) {
      map[jid] = [ msg ];
      return map;
    }

    map[jid]!.add(msg);
    return map;
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
