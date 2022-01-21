import "package:isar/isar.dart";

@Collection()
@Name("Conversation")
class DBConversation {
  int? id;

  @Index(caseSensitive: false)
  late String jid;

  late String title;

  late String avatarUrl;

  late int lastChangeTimestamp;

  late int unreadCounter;

  late String lastMessageBody;

  late bool open;

  late List<String> sharedMediaPaths;
}
