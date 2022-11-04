part of 'own_devices_bloc.dart';

@freezed
class OwnDevicesState with _$OwnDevicesState {
  factory OwnDevicesState({
    @Default(false) bool working,
    @Default([]) List<OmemoDevice> keys,
    @Default(-1) int deviceId,
    @Default('') String deviceFingerprint,
  }) = _OwnDevicesState;
}
