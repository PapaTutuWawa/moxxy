part of 'stickers_bloc.dart';

@freezed
class StickersState with _$StickersState {
  factory StickersState(
    List<StickerPack> stickerPacks,
  ) = _StickersState;
}
