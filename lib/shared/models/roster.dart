import 'package:freezed_annotation/freezed_annotation.dart';

part 'roster.freezed.dart';
part 'roster.g.dart';

@freezed
class RosterItem with _$RosterItem {
  factory RosterItem(
    int id,
    String avatarUrl,
    String avatarHash,
    String jid,
    String title,
    String subscription,
    String ask,
    List<String> groups,
  ) = _RosterItem;

  // JSON
  factory RosterItem.fromJson(Map<String, dynamic> json) => _$RosterItemFromJson(json);
}
