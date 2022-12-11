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
    {
      // The id of the contact in the device's phonebook, if it exists
      String? contactId,
      // The path to the profile picture of the contact, if it exists
      String? contactAvatarPath,
      // The contact's display name, if it exists
      String? contactDisplayName,
    }
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
