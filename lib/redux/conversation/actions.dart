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
  final String from;
  final String jid;
  final int cid;

  SendMessageAction({ required this.from, required this.body, required this.timestamp, required this.jid, required this.cid });
}
