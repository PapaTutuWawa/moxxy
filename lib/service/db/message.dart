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

  /// Url a file can be accessed from
  String? srcUrl;
  /// A file:// URL pointing to the file
  String? mediaUrl;
  /// If the message should be treated as a media message, e.g. an image
  late bool isMedia;
  /// The mime type, if available
  String? mediaType;
  // TODO: Add a flag to specify the thumbnail type
  /// The data of the thumbnail base64-encoded if needed. Currently assumed to be blurhash
  String? thumbnailData;
  /// The dimensions of the thumbnail
  String? thumbnailDimensions;
}
