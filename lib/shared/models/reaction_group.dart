import 'package:freezed_annotation/freezed_annotation.dart';

part 'reaction_group.freezed.dart';
part 'reaction_group.g.dart';

@freezed
class ReactionGroup with _$ReactionGroup {
  factory ReactionGroup(
    String jid,
    List<String> emojis,
  ) = _ReactionGroup;

  /// JSON
  factory ReactionGroup.fromJson(Map<String, dynamic> json) =>
      _$ReactionGroupFromJson(json);
}
