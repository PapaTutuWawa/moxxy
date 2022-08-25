import 'package:isar/isar.dart';

part 'message.g.dart';

@Collection()
@Name('Message')
class DBMessage {
  int? id;

  @Index(caseSensitive: false)
  late String from;

  @Index(caseSensitive: false)
  late String conversationJid;

  late int timestamp;

  late String body;

  // TODO(Unknown): Replace by just checking if sender == us
  /// Indicate if the message was sent by the user (true) or received by the user (false)
  late bool sent;

  late String sid;
  String? originId;

  /// Indicate if the message was received by the client (via Chat Markers or Delivery Receipts) or acked by the server
  late bool acked;
  late bool received;
  late bool displayed;

  /// In case an error is related to the message, this stores an enum-like constant
  /// that clearly identifies the error.
  late int errorType;

  /// If true, then the message is currently a placeholder for a File Upload Notification
  /// and may be replaced
  late bool isFileUploadNotification;
  
  /// The message that this one quotes
  final quotes = IsarLink<DBMessage>();
  
  /// Url a file can be accessed from
  String? srcUrl;
  /// A file:// URL pointing to the file
  String? mediaUrl;
  /// If the message should be treated as a media message, e.g. an image
  late bool isMedia;
  /// The mime type, if available
  String? mediaType;
  // TODO(Unknown): Add a flag to specify the thumbnail type
  /// The data of the thumbnail base64-encoded if needed. Currently assumed to be blurhash
  String? thumbnailData;
  /// The dimensions of the thumbnail
  String? thumbnailDimensions;

  /// The filename of the file. Useful for when we don't have the full URL yet
  String? filename;
}
