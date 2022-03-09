import "package:moxxyv2/xmpp/xeps/xep_0198/state.dart";

import "package:freezed_annotation/freezed_annotation.dart";

part "state.freezed.dart";
part "state.g.dart";

@freezed
class XmppState with _$XmppState {
  factory XmppState(
    String debugPassphrase,
    String debugIp,
    int debugPort,
    bool debugEnabled,
    {
      StreamManagementState? smState,
      String? srid,
      String? resource,
      String? jid,
      String? password,
      String? lastRosterVersion,
      @Default(false) bool askedStoragePermission
  }) = _XmppState;

  // JSON serialization
  factory XmppState.fromJson(Map<String, dynamic> json) => _$XmppStateFromJson(json);
}
