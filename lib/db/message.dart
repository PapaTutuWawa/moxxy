import "package:isar/isar.dart";

@Collection()
@Name("Message")
class DBMessage {
  int? id;

  @Index(caseSensitive: false)
  late String from;

  @Index(caseSensitive: false)
  late String conversationJid;

  late int timestamp;

  late String body;

  late bool sent;
}
