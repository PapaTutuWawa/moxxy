import "package:moxxyv2/service/db/media.dart";

import "package:isar/isar.dart";

part "conversation.g.dart";

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

  final sharedMedia = IsarLinks<DBSharedMedium>();
}
