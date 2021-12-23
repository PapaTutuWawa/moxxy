import 'dart:collection';

import "package:moxxyv2/models/message.dart";
import "package:moxxyv2/redux/conversation/actions.dart";

HashMap<String, List<Message>> messageReducer(HashMap<String, List<Message>> state, MessageAction action) {
  if (action is AddMessageAction) {
    HashMap<String, List<Message>> map = HashMap<String, List<Message>>()..addAll(state);

    Message msg = Message(
      from: action.from,
      body: action.body,
      timestamp: action.timestamp,
      sent: true
    );
    
    // TODO
    if (!map.containsKey("")) {
      map[""] = [ msg ];
      return map;
    }

    // TODO
    map[""]!.add(msg);
    return map;
  }

  return state;
}

MoxxyState moxxyReducer(MoxxyState state, dynamic action) {
  return MoxxyState(
    messages: messageReducer(state.messages, action)
  );
}
