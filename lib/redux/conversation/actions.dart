abstract class MessageAction {}

class SetShowSendButtonAction {
  final bool show;

  SetShowSendButtonAction({ required this.show });
}

class AddMessageAction extends MessageAction {
  final String body;
  final int timestamp;
  final String from;
  final String jid;

  AddMessageAction({ required this.from, required this.body, required this.timestamp, required this.jid });
}
