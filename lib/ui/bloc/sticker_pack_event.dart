part of 'sticker_pack_bloc.dart';

abstract class StickerPackEvent {}

/// Triggered by the UI when the user navigates to a locally available sticker pack
class LocallyAvailableStickerPackRequested extends StickerPackEvent {
  LocallyAvailableStickerPackRequested(this.stickerPackId);
  final String stickerPackId;
}

/// Triggered by the UI when the sticker pack is removed
class StickerPackRemovedEvent extends StickerPackEvent {
  StickerPackRemovedEvent(this.stickerPackId);
  final String stickerPackId;
}
