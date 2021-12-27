class SetShowSendButtonAction {
  final bool show;

  SetShowSendButtonAction({ required this.show });
}

class SetShowScrollToEndButtonAction {
  final bool show;

  SetShowScrollToEndButtonAction({ required this.show });
}

// TODO: Rename to SendMessageAction
class AddMessageAction {
  final String body;
  final int timestamp;
  final String from;
  final String jid;

  AddMessageAction({ required this.from, required this.body, required this.timestamp, required this.jid });
}
