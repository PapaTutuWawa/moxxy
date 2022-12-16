part of 'stickers_bloc.dart';

abstract class StickersEvent {}

class StickersSetEvent extends StickersEvent {
  StickersSetEvent(
    this.stickerPacks,
  );
  final List<StickerPack> stickerPacks;
}
