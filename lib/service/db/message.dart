import "package:isar/isar.dart";

part "message.g.dart";

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

  late String sid;
  String? originId;
  
  String? oobUrl;
  /// A file:// URL pointing to the file
  String? mediaUrl;
  /// If the message should be treated as a media message, e.g. an image
  late bool isMedia;
}
