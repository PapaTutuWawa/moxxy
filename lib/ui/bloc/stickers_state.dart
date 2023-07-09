part of 'stickers_bloc.dart';

@immutable
class StickerKey {
  const StickerKey(this.packId, this.stickerHashKey);
  final String packId;
  final String stickerHashKey;

  @override
  int get hashCode => packId.hashCode ^ stickerHashKey.hashCode;

  @override
  bool operator ==(Object other) {
    return other is StickerKey &&
        other.packId == packId &&
        other.stickerHashKey == stickerHashKey;
  }
}

@freezed
class StickersState with _$StickersState {
  factory StickersState({
    @Default(false) bool isImportRunning,
  }) = _StickersState;
}
