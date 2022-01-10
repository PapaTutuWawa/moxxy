import "package:moxxyv2/models/message.dart";
import "package:moxxyv2/xmpp/jid.dart";

class SetShowSendButtonAction {
  final bool show;

  SetShowSendButtonAction({ required this.show });
}

class SetShowScrollToEndButtonAction {
  final bool show;

  SetShowScrollToEndButtonAction({ required this.show });
}

class SendMessageAction {
  final String body;
  final int timestamp;
  final String jid;

  SendMessageAction({ required this.body, required this.timestamp, required this.jid });
}

class ReceiveMessageAction {
  final String body;
  final int timestamp;
  final FullJID from;
  final String jid;

  ReceiveMessageAction({ required this.from, required this.body, required this.timestamp, required this.jid });
}

class AddMessageAction {
  final Message message;

  AddMessageAction({ required this.message });
}

class AddMultipleMessagesAction {
  final String conversationJid;
  final List<Message> messages;

  AddMultipleMessagesAction({ required this.messages, required this.conversationJid });
}

class CloseConversationAction {
  final String jid;
  final int id;
  final bool redirect;

  CloseConversationAction({ required this.jid, required this.id, this.redirect = true });
}

class SetOpenConversationAction {
  final String? jid;

  SetOpenConversationAction({ this.jid });
}
