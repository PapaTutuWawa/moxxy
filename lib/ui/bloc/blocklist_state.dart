part of "blocklist_bloc.dart";

@freezed
class BlocklistState with _$BlocklistState {
  factory BlocklistState({
      @Default([]) blocklist
  }) = _BlocklistState;
}
