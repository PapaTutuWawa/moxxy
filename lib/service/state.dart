import "package:freezed_annotation/freezed_annotation.dart";

part "state.freezed.dart";
part "state.g.dart";

@freezed
class XmppState with _$XmppState {
  factory XmppState(int c2sh, int s2ch, String debugPassphrase, String debugIp, int debugPort, bool debugEnabled, { String? srid, String? resource, String? jid, String? password, String? lastRosterVersion, @Default(false) bool askedStoragePermission }) = _XmppState;

  // JSON serialization
  factory XmppState.fromJson(Map<String, dynamic> json) => _$XmppStateFromJson(json);
}
