import 'package:freezed_annotation/freezed_annotation.dart';

part 'reaction.freezed.dart';
part 'reaction.g.dart';

@freezed
class Reaction with _$Reaction {
  factory Reaction(
    // This is valid in combination with freezed
    // ignore: invalid_annotation_target
    @JsonKey(name: 'message_id') int messageId,
    String senderJid,
    String emoji,
  ) = _Reaction;

  /// JSON
  factory Reaction.fromJson(Map<String, dynamic> json) =>
      _$ReactionFromJson(json);
}
