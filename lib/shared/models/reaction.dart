import 'package:freezed_annotation/freezed_annotation.dart';

part 'reaction.freezed.dart';
part 'reaction.g.dart';

@freezed
class Reaction with _$Reaction {
  factory Reaction(
    // This is valid in combination with freezed
    // ignore: invalid_annotation_target
    @JsonKey(name: 'message_sid') String messageSid,

    /// The JID of the conversation this reaction is in.
    String conversationJid,

    // The account JID of the attached message.
    String accountJid,

    // The timestamp of the referenced message. Required for database reasons.
    // ignore: invalid_annotation_target
    @JsonKey(name: 'message_timestamp') int timestamp,

    // The sender of the referenced message. Required for database reasons.
    // ignore: invalid_annotation_target 
    @JsonKey(name: 'message_sender') String messageSender,

    // The sender of the reaction.
    String senderJid,

    // The emoji reaction.
    String emoji,
  ) = _Reaction;

  /// JSON
  factory Reaction.fromJson(Map<String, dynamic> json) =>
      _$ReactionFromJson(json);
}
