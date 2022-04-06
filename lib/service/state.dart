import "package:moxxyv2/xmpp/xeps/xep_0198/state.dart";

import "package:freezed_annotation/freezed_annotation.dart";

part "state.freezed.dart";
part "state.g.dart";

class StreamManagementStateConverter implements JsonConverter<StreamManagementState, Map<String, dynamic>> {
  const StreamManagementStateConverter();

  @override
  StreamManagementState fromJson(Map<String, dynamic> json) => StreamManagementState.fromJson(json);
  
  @override
  Map<String, dynamic> toJson(StreamManagementState state) => state.toJson();
}

@freezed
class XmppState with _$XmppState {
  factory XmppState({
      @StreamManagementStateConverter() StreamManagementState? smState,
      String? srid,
      String? resource,
      String? jid,
      String? displayName,
      String? password,
      String? lastRosterVersion,
      @Default("") avatarUrl,
      @Default("") avatarHash,
      @Default(false) bool askedStoragePermission
  }) = _XmppState;

  // JSON serialization
  factory XmppState.fromJson(Map<String, dynamic> json) => _$XmppStateFromJson(json);
}
