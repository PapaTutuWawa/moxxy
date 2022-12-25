part of 'blocklist_bloc.dart';

@freezed
class BlocklistState with _$BlocklistState {
  factory BlocklistState({
    @Default(<String>[]) List<String> blocklist,
    @Default(false) bool isWorking,
  }) = _BlocklistState;
}
