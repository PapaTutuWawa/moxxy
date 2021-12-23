import "package:moxxyv2/models/conversation.dart";
import "package:moxxyv2/redux/conversations/actions.dart";

List<Conversation> conversationReducer(List<Conversation> state, dynamic action) {
  if (action is AddConversationAction) {
    state.add(Conversation(
        title: action.title,
        lastMessageBody: action.lastMessageBody,
        avatarUrl: action.avatarUrl,
        jid: action.jid
    ));
  }

  return state;
}
