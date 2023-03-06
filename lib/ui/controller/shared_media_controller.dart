import 'dart:async';
import 'package:moxplatform/moxplatform.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/constants.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/shared/models/media.dart';
import 'package:moxxyv2/ui/controller/bidirectional_controller.dart';

class BidirectionalSharedMediaController
    extends BidirectionalController<SharedMedium> {
  BidirectionalSharedMediaController(this.conversationJid)
      : assert(
          BidirectionalSharedMediaController.currentController == null,
          'There can only be one BidirectionalSharedMediaController',
        ),
        super(
          pageSize: sharedMediaPaginationSize,
          maxPageAmount: maxSharedMediaPages,
        ) {
    BidirectionalSharedMediaController.currentController = this;
  }

  /// A singleton referring to the current instance as there can only be one
  /// BidirectionalConversationController at a time.
  static BidirectionalSharedMediaController? currentController;

  final String conversationJid;

  @override
  Future<List<SharedMedium>> fetchOlderDataImpl(
    SharedMedium? oldestElement,
  ) async {
    // ignore: cast_nullable_to_non_nullable
    final result = await MoxplatformPlugin.handler.getDataSender().sendData(
          GetPagedSharedMediaCommand(
            conversationJid: conversationJid,
            timestamp: oldestElement?.timestamp,
            olderThan: true,
          ),
        ) as PagedSharedMediaResultEvent;

    return result.media;
  }

  @override
  Future<List<SharedMedium>> fetchNewerDataImpl(
    SharedMedium? newestElement,
  ) async {
    // ignore: cast_nullable_to_non_nullable
    final result = await MoxplatformPlugin.handler.getDataSender().sendData(
          GetPagedSharedMediaCommand(
            conversationJid: conversationJid,
            timestamp: newestElement?.timestamp,
            olderThan: false,
          ),
        ) as PagedSharedMediaResultEvent;

    return result.media;
  }

  @override
  void dispose() {
    super.dispose();
    BidirectionalSharedMediaController.currentController = null;
  }
}
