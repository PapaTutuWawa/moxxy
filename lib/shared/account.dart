import "package:freezed_annotation/freezed_annotation.dart";

part "account.freezed.dart";
part "account.g.dart";

@freezed
class AccountState with _$AccountState {
  factory AccountState({
      @Default("") String jid,
      @Default("") String displayName,
      @Default("") String avatarUrl
  }) = _AccountState;
  
  // JSON serialization
  factory AccountState.fromJson(Map<String, dynamic> json) => _$AccountStateFromJson(json);
}
