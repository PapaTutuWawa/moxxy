part of 'stickers_bloc.dart';

@immutable
class StickerKey {
  const StickerKey(this.packId, this.stickerId);
  final String packId;
  final int stickerId;

  @override
  int get hashCode => packId.hashCode ^ stickerId.hashCode;

  @override
  bool operator ==(Object other) {
    return other is StickerKey && other.packId == packId && other.stickerId == stickerId;
  }
}

@freezed
class StickersState with _$StickersState {
  factory StickersState({
    @Default([]) List<StickerPack> stickerPacks,
    @Default({}) Map<StickerKey, Sticker> stickerMap,
  }) = _StickersState;
}
