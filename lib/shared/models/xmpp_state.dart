import 'dart:convert';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:moxxmpp/moxxmpp.dart';

part 'xmpp_state.freezed.dart';
part 'xmpp_state.g.dart';

class StreamManagementStateConverter
    implements JsonConverter<StreamManagementState, Map<String, dynamic>> {
  const StreamManagementStateConverter();

  @override
  StreamManagementState fromJson(Map<String, dynamic> json) =>
      StreamManagementState.fromJson(json);

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
    @Default('') String avatarUrl,
    @Default('') String avatarHash,
    @Default(false) bool askedStoragePermission,
  }) = _XmppState;

  const XmppState._();

  // JSON serialization
  factory XmppState.fromJson(Map<String, dynamic> json) =>
      _$XmppStateFromJson(json);

  factory XmppState.fromDatabaseTuples(Map<String, String?> tuples) {
    final smStateString = tuples['smState'];
    final isSmStateNotNull = smStateString != null && smStateString != 'null';
    final json = <String, dynamic>{
      'smState': isSmStateNotNull
          ? jsonDecode(smStateString) as Map<String, dynamic>
          : null,
      'srid': tuples['srid'],
      'resource': tuples['resource'],
      'jid': tuples['jid'],
      'displayName': tuples['displayName'],
      'password': tuples['password'],
      'lastRosterVersion': tuples['lastRosterVersion'],
      'avatarUrl': tuples['avatarUrl'],
      'avatarHash': tuples['avatarHash'],
      'askedStoragePermission': tuples['askedStoragePermission'] == 'true',
    };

    return XmppState.fromJson(json);
  }

  Map<String, String?> toDatabaseTuples() {
    final json = toJson()
      ..remove('smState')
      ..remove('askedStoragePermission');

    return {
      ...json.cast<String, String?>(),
      'smState': jsonEncode(smState?.toJson()),
      'askedStoragePermission': askedStoragePermission ? 'true' : 'false',
    };
  }
}
