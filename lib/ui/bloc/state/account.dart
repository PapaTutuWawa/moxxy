import 'package:freezed_annotation/freezed_annotation.dart';

part 'account.freezed.dart';

@freezed
class AccountState with _$AccountState {
  factory AccountState({
    // The displayname to use.
    @Default('') String displayName,

    // The path to the account's profile picture.
    String? avatarPath,

    // The hash of our own avatar.
    String? avatarHash,

    // The account's JID.
    @Default('') String jid,
  }) = _AccountState;
}
