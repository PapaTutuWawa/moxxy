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

  const RosterItem._();
  
  /// JSON
  factory RosterItem.fromJson(Map<String, dynamic> json) => _$RosterItemFromJson(json);

  factory RosterItem.fromDatabaseJson(Map<String, dynamic> json) {
    return RosterItem.fromJson({
      ...json,
      // TODO(PapaTutuWawa): Fix
      'groups': <String>[],
    });
  }

  Map<String, dynamic> toDatabaseJson() {
    return toJson()
      ..remove('id')
      // TODO(PapaTutuWawa): Fix
      ..remove('groups');
  }
}
