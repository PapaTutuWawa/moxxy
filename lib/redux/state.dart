import "dart:collection";
import "package:moxxyv2/redux/conversation/reducers.dart";
import "package:moxxyv2/redux/conversations/reducers.dart";
import "package:moxxyv2/redux/login/reducers.dart";
import "package:moxxyv2/redux/registration/reducers.dart";
import "package:moxxyv2/redux/postregister/reducers.dart";
import "package:moxxyv2/redux/profile/reducers.dart";
import "package:moxxyv2/redux/account/reducers.dart";
import "package:moxxyv2/redux/global/reducers.dart";
import "package:moxxyv2/redux/roster/reducers.dart";
import "package:moxxyv2/redux/login/state.dart";
import "package:moxxyv2/redux/conversation/state.dart";
import "package:moxxyv2/redux/registration/state.dart";
import "package:moxxyv2/redux/postregister/state.dart";
import "package:moxxyv2/redux/profile/state.dart";
import "package:moxxyv2/redux/account/state.dart";
import "package:moxxyv2/redux/global/state.dart";
import "package:moxxyv2/models/message.dart";
import "package:moxxyv2/models/conversation.dart";
import "package:moxxyv2/models/roster.dart";

MoxxyState moxxyReducer(MoxxyState state, dynamic action) {
  return MoxxyState(
    messages: messageReducer(state.messages, action),
    conversations: conversationReducer(state.conversations, action),
    roster: rosterReducer(state.roster, action),
    loginPageState: loginReducer(state.loginPageState, action),
    conversationPageState: conversationPageReducer(state.conversationPageState, action),
    registerPageState: registerReducer(state.registerPageState, action),
    postRegisterPageState: postRegisterReducer(state.postRegisterPageState, action),
    profilePageState: profileReducer(state.profilePageState, action),
    accountState: accountReducer(state.accountState, action),
    globalState: globalReducer(state.globalState, action)
  );
}

class MoxxyState {
  final HashMap<String, List<Message>> messages;
  final List<Conversation> conversations;
  final List<RosterItem> roster;
  final LoginPageState loginPageState;
  final ConversationPageState conversationPageState;
  final RegisterPageState registerPageState;
  final PostRegisterPageState postRegisterPageState;
  final ProfilePageState profilePageState;
  final AccountState accountState;
  final GlobalState globalState;

  const MoxxyState({ required this.messages, required this.conversations, required this.roster, required this.loginPageState, required this.conversationPageState, required this.registerPageState, required this.postRegisterPageState, required this.profilePageState, required this.accountState, required this.globalState });
  MoxxyState.initialState() : messages = HashMap(), conversations = List.empty(growable: true), roster = List.empty(growable: true), loginPageState = LoginPageState.initialState(), conversationPageState = ConversationPageState.initialState(), registerPageState = RegisterPageState.initialState(), postRegisterPageState = PostRegisterPageState.initialState(), profilePageState = ProfilePageState.initialState(), accountState = AccountState.initialState(), globalState = GlobalState.initialState();
}
