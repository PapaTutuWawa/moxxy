part of 'keys_bloc.dart';

@freezed
class KeysState with _$KeysState {
  factory KeysState({
    @Default(false) bool working,
    @Default([]) List<OmemoKey> keys,
  }) = _KeysState;
}
