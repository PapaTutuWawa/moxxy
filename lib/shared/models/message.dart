import "package:freezed_annotation/freezed_annotation.dart";

part "message.freezed.dart";
part "message.g.dart";

@freezed
class Message with _$Message {
  // NOTE: id is the database id of the message
  // NOTE: isMedia is for telling the UI that this message contains the URL for media but the path is not yet available
  
  factory Message(String from, String body, int timestamp, bool sent, int id, String conversationJid, bool isMedia, { String? mediaUrl }) = _Message;

  // JSON
  factory Message.fromJson(Map<String, dynamic> json) => _$MessageFromJson(json);
}
