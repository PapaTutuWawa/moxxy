import "dart:collection";

class AddConversationAction {
  final String title;
  final String lastMessageBody;
  final String avatarUrl;
  final String jid;
  final int id;
  final int unreadCounter;
  final List<String> sharedMediaPaths;
  final int lastChangeTimestamp;
  final bool triggeredByDatabase;

  AddConversationAction({ required this.title, required this.lastMessageBody, required this.avatarUrl, required this.jid, required this.sharedMediaPaths, required this.lastChangeTimestamp, required this.id, this.unreadCounter = 0, this.triggeredByDatabase = false });
}
