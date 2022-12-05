import 'package:freezed_annotation/freezed_annotation.dart';

part 'reaction.freezed.dart';
part 'reaction.g.dart';

@freezed
class Reaction with _$Reaction {
  factory Reaction(
    List<String> senders,
    String emoji,
    // NOTE: Store this with the model to prevent having to to a O(n) search across the
    //       list of reactions on every rebuild
    bool reactedBySelf,
  ) = _Reaction;

  /// JSON
  factory Reaction.fromJson(Map<String, dynamic> json) => _$ReactionFromJson(json);
}
