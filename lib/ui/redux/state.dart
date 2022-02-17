import "dart:collection";

import "package:moxxyv2/ui/redux/conversation/reducers.dart";
import "package:moxxyv2/ui/redux/conversations/reducers.dart";
import "package:moxxyv2/ui/redux/login/reducers.dart";
import "package:moxxyv2/ui/redux/registration/reducers.dart";
import "package:moxxyv2/ui/redux/postregister/reducers.dart";
import "package:moxxyv2/ui/redux/profile/reducers.dart";
import "package:moxxyv2/ui/redux/account/reducers.dart";
import "package:moxxyv2/ui/redux/global/reducers.dart";
import "package:moxxyv2/ui/redux/roster/reducers.dart";
import "package:moxxyv2/ui/redux/login/state.dart";
import "package:moxxyv2/ui/redux/conversation/state.dart";
import "package:moxxyv2/ui/redux/registration/state.dart";
import "package:moxxyv2/ui/redux/postregister/state.dart";
import "package:moxxyv2/ui/redux/profile/state.dart";
import "package:moxxyv2/ui/redux/account/state.dart";
import "package:moxxyv2/ui/redux/global/state.dart";
import "package:moxxyv2/ui/redux/addcontact/reducers.dart";
import "package:moxxyv2/ui/redux/debug/state.dart";
import "package:moxxyv2/ui/redux/debug/reducers.dart";
import "package:moxxyv2/shared/models/message.dart";
import "package:moxxyv2/shared/models/conversation.dart";
import "package:moxxyv2/shared/models/roster.dart";

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
    globalState: globalReducer(state.globalState, action),
    debugState: debugReducer(state.debugState, action),
    openConversationJid: openConversationJidReducer(state.openConversationJid, action),
    addContactErrorText: addContactErrorTextReducer(state.addContactErrorText, action)
  );
}

class MoxxyState {
  final HashMap<String, List<Message>> messages;
  final HashMap<String, Conversation> conversations;
  final List<RosterItem> roster;
  final LoginPageState loginPageState;
  final ConversationPageState conversationPageState;
  final RegisterPageState registerPageState;
  final PostRegisterPageState postRegisterPageState;
  final ProfilePageState profilePageState;
  final AccountState accountState;
  final GlobalState globalState;
  final DebugState debugState;

  final String? openConversationJid;
  final String? addContactErrorText;

  const MoxxyState({
      required this.messages,
      required this.conversations,
      required this.roster,
      required this.loginPageState,
      required this.conversationPageState,
      required this.registerPageState,
      required this.postRegisterPageState,
      required this.profilePageState,
      required this.accountState,
      required this.globalState,
      required this.debugState,
      this.openConversationJid,
      this.addContactErrorText
  });
  MoxxyState.initialState()
    : messages = HashMap(),
      conversations = HashMap(),
      roster = List.empty(growable: true),
      loginPageState = LoginPageState.initialState(),
      conversationPageState = ConversationPageState.initialState(),
      registerPageState = RegisterPageState.initialState(),
      postRegisterPageState = PostRegisterPageState.initialState(),
      profilePageState = ProfilePageState.initialState(),
      accountState = const AccountState.initialState(),
      globalState = GlobalState.initialState(),
      debugState = const DebugState.initialState(),
      openConversationJid = null,
      addContactErrorText = null;
}
