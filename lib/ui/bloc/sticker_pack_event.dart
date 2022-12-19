part of 'sticker_pack_bloc.dart';

abstract class StickerPackEvent {}

/// Triggered by the UI when the user navigates to a locally available sticker pack
class LocallyAvailableStickerPackRequested extends StickerPackEvent {
  LocallyAvailableStickerPackRequested(this.stickerPackId);
  final String stickerPackId;
}

/// Triggered by the UI when the user navigates to a remote sticker pack
class RemoteStickerPackRequested extends StickerPackEvent {
  RemoteStickerPackRequested(this.stickerPackId, this.jid);
  final String stickerPackId;
  final String jid;
}

/// Triggered by the UI when the sticker pack is removed
class StickerPackRemovedEvent extends StickerPackEvent {
  StickerPackRemovedEvent(this.stickerPackId);
  final String stickerPackId;
}

/// Triggered by the UI when the sticker pack currently displayed is to be installed
class StickerPackInstalledEvent extends StickerPackEvent {}

/// Triggered by the UI when a URL has been tapped that contains a sticker pack that
/// or may not be locally available.
class StickerPackRequested extends StickerPackEvent {
  StickerPackRequested(this.jid, this.stickerPackId);
  final String jid;
  final String stickerPackId;
}
