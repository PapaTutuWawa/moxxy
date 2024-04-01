import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxyv2/service/database/helpers.dart';
import 'package:moxxyv2/service/preferences.dart';
import 'package:moxxyv2/ui/bloc/preferences.dart';

part 'roster.freezed.dart';
part 'roster.g.dart';

@freezed
class RosterItem with _$RosterItem {
  factory RosterItem(
    // The the JID of the account this roster belongs to.
    String accountJid,

    // Path to the roster avatar.
    String? avatarPath,

    // The SHA-1 hash of the roster avatar.
    String? avatarHash,

    // The JID of the roster item.
    String jid,

    // The title of the roster item.
    String title,

    // The subscription state of the roster item.
    String subscription,

    // The ask attribute of the roster item.
    String ask,

    // Indicates whether the "roster item" really exists on the roster and is not just there
    // for the contact integration
    bool pseudoRosterItem,

    // A list of groups the roster item is in.
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

  /// The title of the roster item. This returns, if [contactIntegration] is true, first the contact's display
  /// name, then the XMPP roster title. If [contactIntegration] is false, just returns the XMPP roster
  /// title.
  String getTitleWithOptionalContact(bool contactIntegration) {
    if (contactIntegration) {
      return contactDisplayName ?? title;
    }

    return title;
  }

  /// This getter is a short-hand for [getTitleWithOptionalContact] with the
  /// contact integration enablement status extracted from the [PreferencesCubit].
  /// NOTE: This method only works in the UI.
  String get titleWithOptionalContact => getTitleWithOptionalContact(
        GetIt.I.get<PreferencesCubit>().state.enableContactIntegration,
      );

  /// This getter is a short-hand for [getTitleWithOptionalContact] with the
  /// contact integration enablement status extracted from the [PreferencesService].
  /// NOTE: This method only works in the background isolate.
  Future<String> get titleWithOptionalContactService async =>
      getTitleWithOptionalContact(
        (await GetIt.I.get<PreferencesService>().getPreferences())
            .enableContactIntegration,
      );
}
