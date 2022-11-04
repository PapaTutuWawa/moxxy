part of 'devices_bloc.dart';

@freezed
class DevicesState with _$DevicesState {
  factory DevicesState({
    @Default(false) bool working,
    @Default([]) List<OmemoDevice> devices,
    @Default('') String jid,
  }) = _DevicesState;
}
