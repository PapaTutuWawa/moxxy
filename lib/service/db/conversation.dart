import 'package:isar/isar.dart';
import 'package:moxxyv2/service/db/media.dart';

part 'conversation.g.dart';

@Collection()
@Name('Conversation')
class DBConversation {
  Id? id;

  @Index(caseSensitive: false)
  late String jid;

  late String title;

  late String avatarUrl;

  late int lastChangeTimestamp;

  late int unreadCounter;

  late String lastMessageBody;

  late bool open;

  late bool muted;
  
  final sharedMedia = IsarLinks<DBSharedMedium>();
}
