import "dart:collection";
import "package:moxxyv2/redux/conversation/reducers.dart";
import "package:moxxyv2/redux/conversations/reducers.dart";
import "package:moxxyv2/models/message.dart";
import "package:moxxyv2/models/conversation.dart";

MoxxyState moxxyReducer(MoxxyState state, dynamic action) {
  return MoxxyState(
    messages: messageReducer(state.messages, action),
    conversations: conversationReducer(state.conversations, action)
  );
}

class MoxxyState {
  final HashMap<String, List<Message>> messages;
  final List<Conversation> conversations;

  const MoxxyState({ required this.messages, required this.conversations });
  MoxxyState.initialState() : messages = HashMap(), conversations = List.empty(growable: true);
}
