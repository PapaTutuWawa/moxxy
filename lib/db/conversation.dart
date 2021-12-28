import "package:isar/isar.dart";
import "package:moxxyv2/isar.g.dart";

@Collection()
@Name("Conversation")
class Conversation {
  int? id;

  @Index(caseSensitive: false)
  late String jid;

  late String title;

  late String avatarUrl;

  late int lastChangeTimestamp;

  late int unreadCounter;

  late String lastMessageBody;

  // sharedMediaPaths
}
