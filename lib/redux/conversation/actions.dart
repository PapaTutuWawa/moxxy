abstract class MessageAction {}

class AddMessageAction extends MessageAction {
  final String body;
  final String timestamp;
  final String from;

  AddMessageAction({ required this.from, required this.body, required this.timestamp });
}
