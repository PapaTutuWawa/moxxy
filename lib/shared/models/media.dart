import 'package:freezed_annotation/freezed_annotation.dart';

part 'media.freezed.dart';
part 'media.g.dart';

@freezed
class SharedMedium with _$SharedMedium {
  factory SharedMedium(
    int id,
    String path,
    int timestamp,
    String conversationJid,
    {
      String? mime,
      int? messageId,
    }
  ) = _SharedMedia;

  const SharedMedium._();
  
  /// JSON
  factory SharedMedium.fromJson(Map<String, dynamic> json) => _$SharedMediumFromJson(json);

  factory SharedMedium.fromDatabaseJson(Map<String, dynamic> json) {
    return SharedMedium.fromJson({
      ...json,
      'messageId': json['message_id'] as int?,
      'conversationJid': json['conversation_jid']! as String,
    });
  }

  Map<String, dynamic> toDatabaseJson() {
    return {
      ...toJson()
        ..remove('id')
        ..remove('messageId')
        ..remove('conversationJid'),
      'message_id': messageId,
      'conversation_jid': conversationJid,
    };
  }
}
