import "dart:collection";
import "package:moxxyv2/redux/conversation/reducers.dart";
import "package:moxxyv2/redux/conversations/reducers.dart";
import "package:moxxyv2/redux/login/reducers.dart";
import "package:moxxyv2/redux/addcontact/reducers.dart";
import "package:moxxyv2/ui/pages/login/state.dart";
import "package:moxxyv2/ui/pages/conversation/state.dart";
import "package:moxxyv2/ui/pages/addcontact/state.dart";
import "package:moxxyv2/models/message.dart";
import "package:moxxyv2/models/conversation.dart";

MoxxyState moxxyReducer(MoxxyState state, dynamic action) {
  return MoxxyState(
    messages: messageReducer(state.messages, action),
    conversations: conversationReducer(state.conversations, action),
    loginPageState: loginReducer(state.loginPageState, action),
    conversationPageState: conversationPageReducer(state.conversationPageState, action),
    addContactPageState: addContactPageReducer(state.addContactPageState, action)
  );
}

class MoxxyState {
  final HashMap<String, List<Message>> messages;
  final List<Conversation> conversations;
  final LoginPageState loginPageState;
  final ConversationPageState conversationPageState;
  final AddContactPageState addContactPageState;

  const MoxxyState({ required this.messages, required this.conversations, required this.loginPageState, required this.conversationPageState, required this.addContactPageState });
  MoxxyState.initialState() : messages = HashMap(), conversations = List.empty(growable: true), loginPageState = LoginPageState(doingWork: false, showPassword: false), conversationPageState = ConversationPageState(showSendButton: false), addContactPageState = AddContactPageState(doingWork: false);
}
