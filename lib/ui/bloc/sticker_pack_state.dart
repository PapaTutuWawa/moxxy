part of 'sticker_pack_bloc.dart';

@freezed
class StickerPackState with _$StickerPackState {
  factory StickerPackState({
    StickerPack? stickerPack,
    @Default(false) bool isWorking,
  }) = _StickerPackState;
}
