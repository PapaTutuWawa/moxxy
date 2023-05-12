import 'package:freezed_annotation/freezed_annotation.dart';

part 'reaction.freezed.dart';
part 'reaction.g.dart';

@freezed
class Reaction with _$Reaction {
  factory Reaction(
    int message_id,
    String senderJid,
    String emoji,
  ) = _Reaction;

  const Reaction._();

  /// JSON
  factory Reaction.fromJson(Map<String, dynamic> json) =>
      _$ReactionFromJson(json);
}
