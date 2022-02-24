import "dart:collection";

import "package:moxxyv2/shared/models/message.dart";
import "package:moxxyv2/ui/redux/conversation/state.dart";
import "package:moxxyv2/ui/redux/conversation/actions.dart";

String? openConversationJidReducer(String? openConversationJid, dynamic action) {
  if (action is SetOpenConversationAction) {
    return action.jid;
  }

  return openConversationJid;
}

HashMap<String, List<Message>> messageReducer(HashMap<String, List<Message>> state, dynamic action) {
  if (action is AddMessageAction) {
    if (!state.containsKey(action.message.conversationJid)) {
      state[action.message.conversationJid] = List.from([ action.message ]);
    } else {
      state[action.message.conversationJid] = state[action.message.conversationJid]!..add(action.message);
    }

    return state;
  } else if (action is AddMultipleMessagesAction) {
    if (action.replace) {
      state[action.conversationJid] = action.messages;
    } else {
      final messages = state[action.conversationJid] ?? List.empty(growable: true);
      state[action.conversationJid] = messages..addAll(action.messages);
    }

    return state;
  } else if (action is AddConversationAction) {
    if (!state.containsKey(action.conversation.jid)) {
      state[action.conversation.jid] = List.empty(growable: true);
    }
  } else if (action is UpdateMessageAction) {
    // If we haven't loaded the conversation yet, we don't need to edit it
    if (state.containsKey(action.message.conversationJid)) {
      final messages = state[action.message.conversationJid]!;
      state[action.message.conversationJid] = messages.map((m) {
          if (m.id == action.message.id) return action.message;

          return m;
      }).toList();
    }
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
