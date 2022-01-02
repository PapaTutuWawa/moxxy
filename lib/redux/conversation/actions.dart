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

class CloseConversationAction {
  final String jid;
  final int id;

  CloseConversationAction({ required this.jid, required this.id });
}
