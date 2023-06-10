import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:moxxyv2/service/database/helpers.dart';

part 'roster.freezed.dart';
part 'roster.g.dart';

@freezed
class RosterItem with _$RosterItem {
  factory RosterItem(
    int id,
    String avatarPath,
    String avatarHash,
    String jid,
    String title,
    String subscription,
    String ask,
    // Indicates whether the "roster item" really exists on the roster and is not just there
    // for the contact integration
    bool pseudoRosterItem,
    List<String> groups, {
    // The id of the contact in the device's phonebook, if it exists
    String? contactId,
    // The path to the profile picture of the contact, if it exists
    String? contactAvatarPath,
    // The contact's display name, if it exists
    String? contactDisplayName,
  }) = _RosterItem;

  const RosterItem._();

  /// JSON
  factory RosterItem.fromJson(Map<String, dynamic> json) =>
      _$RosterItemFromJson(json);

  factory RosterItem.fromDatabaseJson(Map<String, dynamic> json) {
    return RosterItem.fromJson({
      ...json,
      // TODO(PapaTutuWawa): Fix
      'groups': <String>[],
      'pseudoRosterItem': intToBool(json['pseudoRosterItem']! as int),
    });
  }

  Map<String, dynamic> toDatabaseJson() {
    final json = toJson()
      ..remove('id')
      // TODO(PapaTutuWawa): Fix
      ..remove('groups')
      ..remove('pseudoRosterItem');

    return {
      ...json,
      'pseudoRosterItem': boolToInt(pseudoRosterItem),
    };
  }

  /// Whether a conversation with this roster item should display the "Add to roster" button.
  bool get showAddToRosterButton {
    // Those chats are not dealt with on the roster
    if (pseudoRosterItem) {
      return false;
    }

    // A full presence subscription is already achieved. Nothing to do
    if (subscription == 'both') {
      return false;
    }

    // We are not yet waiting for a response to the presence request
    if (ask == 'subscribe' && ['none', 'from', 'to'].contains(subscription)) {
      return false;
    }

    return true;
  }
}
