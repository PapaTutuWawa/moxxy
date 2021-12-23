import 'dart:collection';

import "package:moxxyv2/models/message.dart";
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
