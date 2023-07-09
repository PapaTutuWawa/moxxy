part of 'stickers_bloc.dart';

abstract class StickersEvent {}

/// Triggered by the UI when a sticker pack has been removed
class StickerPackRemovedEvent extends StickersEvent {
  StickerPackRemovedEvent(this.stickerPackId);
  final String stickerPackId;
}

/// Triggered by the UI when a sticker pack has been imported
class StickerPackImportedEvent extends StickersEvent {}

/// Triggered by the UI when a sticker pack has been imported
class StickerPackAddedEvent extends StickersEvent {
  StickerPackAddedEvent(this.stickerPack);
  final StickerPack stickerPack;
}
