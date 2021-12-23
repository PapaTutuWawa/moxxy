abstract class ConversationAction {}

class AddConversationAction extends ConversationAction {
  final String title;
  final String lastMessageBody;
  final String avatarUrl;
  final String jid;

  AddConversationAction({ required this.title, required this.lastMessageBody, required this.avatarUrl, required this.jid });
}
