import 'dart:convert';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:moxxmpp/moxxmpp.dart';

part 'xmpp_state.freezed.dart';
part 'xmpp_state.g.dart';

extension StreamManagementStateToJson on StreamManagementState {
  Map<String, dynamic> toJson() => {
        'c2s': c2s,
        's2c': s2c,
        'streamResumptionLocation': streamResumptionLocation,
        'streamResumptionId': streamResumptionId,
      };
}

class StreamManagementStateConverter
    implements JsonConverter<StreamManagementState, Map<String, dynamic>> {
  const StreamManagementStateConverter();

  @override
  StreamManagementState fromJson(Map<String, dynamic> json) =>
      StreamManagementState(
        json['c2s']! as int,
        json['s2c']! as int,
        streamResumptionLocation: json['streamResumptionLocation'] as String?,
        streamResumptionId: json['streamResumptionId'] as String?,
      );

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
    String? fastToken,
    @Default('') String avatarUrl,
    @Default('') String avatarHash,
    @Default(false) bool askedStoragePermission,
    @Default(false) bool askedNotificationPermission,
    @Default(false) bool askedBatteryOptimizationExcemption,
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
      'askedNotificationPermission':
          tuples['askedNotificationPermission'] == 'true',
      'askedBatteryOptimizationExcemption':
          tuples['askedBatteryOptimizationExcemption'] == 'true',
    };

    return XmppState.fromJson(json);
  }

  Map<String, String?> toDatabaseTuples() {
    final json = toJson()
      ..remove('smState')
      ..remove('askedStoragePermission')
      ..remove('askedNotificationPermission')
      ..remove('askedBatteryOptimizationExcemption');

    return {
      ...json.cast<String, String?>(),
      'smState': jsonEncode(smState?.toJson()),
      'askedStoragePermission': askedStoragePermission ? 'true' : 'false',
      'askedNotificationPermission':
          askedNotificationPermission ? 'true' : 'false',
      'askedBatteryOptimizationExcemption':
          askedBatteryOptimizationExcemption ? 'true' : 'false',
    };
  }
}
