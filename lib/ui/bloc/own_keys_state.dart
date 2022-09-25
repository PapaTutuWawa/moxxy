part of 'own_keys_bloc.dart';

@freezed
class OwnKeysState with _$OwnKeysState {
  factory OwnKeysState({
    @Default(false) bool working,
    @Default([]) List<OmemoKey> keys,
    @Default(-1) int deviceId,
    @Default('') String deviceFingerprint,
  }) = _OwnKeysState;
}
