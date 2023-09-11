import 'package:moxxy_native/moxxy_native.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/constants.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/shared/models/sticker_pack.dart';
import 'package:moxxyv2/ui/controller/bidirectional_controller.dart';

class BidirectionalStickerPackController
    extends BidirectionalController<StickerPack> {
  BidirectionalStickerPackController(this.includeStickers)
      : assert(
          instance == null,
          'There can only be one BidirectionalStickerPackController',
        ),
        super(
          pageSize: stickerPackPaginationSize,
          maxPageAmount: maxStickerPackPages,
        ) {
    instance = this;
  }

  /// A flag telling the UI to also include stickers in the sticker pack requests.
  final bool includeStickers;

  /// Singleton instance access.
  static BidirectionalStickerPackController? instance;

  @override
  void dispose() {
    super.dispose();

    instance = null;
  }

  @override
  Future<List<StickerPack>> fetchOlderDataImpl(
    StickerPack? oldestElement,
  ) async {
    // ignore: cast_nullable_to_non_nullable
    final result = await getForegroundService().send(
      GetPagedStickerPackCommand(
        olderThan: true,
        timestamp: oldestElement?.addedTimestamp,
        includeStickers: includeStickers,
      ),
    ) as PagedStickerPackResult;

    return result.stickerPacks;
  }

  @override
  Future<List<StickerPack>> fetchNewerDataImpl(
    StickerPack? newestElement,
  ) async {
    // ignore: cast_nullable_to_non_nullable
    final result = await getForegroundService().send(
      GetPagedStickerPackCommand(
        olderThan: false,
        timestamp: newestElement?.addedTimestamp,
        includeStickers: includeStickers,
      ),
    ) as PagedStickerPackResult;

    return result.stickerPacks;
  }
}
