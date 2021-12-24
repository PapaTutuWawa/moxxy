import "dart:collection";

class AddConversationAction {
  final String title;
  final String lastMessageBody;
  final String avatarUrl;
  final String jid;
  final List<String> sharedMediaPaths;

  AddConversationAction({ required this.title, required this.lastMessageBody, required this.avatarUrl, required this.jid, required this.sharedMediaPaths });
}
