import 'package:moxplatform/moxplatform.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/constants.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/shared/models/sticker_pack.dart';
import 'package:moxxyv2/ui/controller/bidirectional_controller.dart';

class BidirectionalStickerPackController
    extends BidirectionalController<StickerPack> {
  BidirectionalStickerPackController()
      : super(
          pageSize: stickerPackPaginationSize,
          maxPageAmount: maxStickerPackPages,
        );

  @override
  Future<List<StickerPack>> fetchOlderDataImpl(
    StickerPack? oldestElement,
  ) async {
    // ignore: cast_nullable_to_non_nullable
    final result = await MoxplatformPlugin.handler.getDataSender().sendData(
          GetPagedStickerPackCommand(
            olderThan: true,
            timestamp: oldestElement?.addedTimestamp,
          ),
        ) as PagedStickerPackResult;

    return result.stickerPacks;
  }

  @override
  Future<List<StickerPack>> fetchNewerDataImpl(
    StickerPack? newestElement,
  ) async {
    // ignore: cast_nullable_to_non_nullable
    final result = await MoxplatformPlugin.handler.getDataSender().sendData(
          GetPagedStickerPackCommand(
            olderThan: false,
            timestamp: newestElement?.addedTimestamp,
          ),
        ) as PagedStickerPackResult;

    return result.stickerPacks;
  }
}
