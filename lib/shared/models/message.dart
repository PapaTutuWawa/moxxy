import 'package:freezed_annotation/freezed_annotation.dart';

part 'message.freezed.dart';
part 'message.g.dart';

@freezed
class Message with _$Message {
  // NOTE: id is the database id of the message
  // NOTE: isMedia is for telling the UI that this message contains the URL for media but the path is not yet available
  // NOTE: srcUrl is the Url that a file has been or can be downloaded from
  
  factory Message(
    String from,
    String body,
    int timestamp,
    bool sent,
    String sid,
    int id,
    String conversationJid,
    bool isMedia,
    {
      String? mediaUrl,
      @Default(false) bool isDownloading,
      String? mediaType,
      String? thumbnailData,
      String? thumbnailDimensions,
      String? srcUrl,
      @Default(false) bool received,
      @Default(false) bool displayed,
      @Default(false) bool acked,
      String? originId,
      Message? quotes,
    }
  ) = _Message;

  // JSON
  factory Message.fromJson(Map<String, dynamic> json) => _$MessageFromJson(json);
}
