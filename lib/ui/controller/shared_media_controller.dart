import 'dart:async';
import 'package:moxplatform/moxplatform.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/constants.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/ui/controller/bidirectional_controller.dart';

class BidirectionalSharedMediaController
    extends BidirectionalController<Message> {
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

  /// The JID of the conversation we want to get shared media of.
  final String? conversationJid;

  @override
  Future<List<Message>> fetchOlderDataImpl(
    Message? oldestElement,
  ) async {
    // ignore: cast_nullable_to_non_nullable
    final result = await MoxplatformPlugin.handler.getDataSender().sendData(
          GetPagedSharedMediaCommand(
            conversationJid: conversationJid,
            timestamp: oldestElement?.timestamp,
            olderThan: true,
          ),
        ) as PagedMessagesResultEvent;

    return result.messages;
  }

  @override
  Future<List<Message>> fetchNewerDataImpl(
    Message? newestElement,
  ) async {
    // ignore: cast_nullable_to_non_nullable
    final result = await MoxplatformPlugin.handler.getDataSender().sendData(
          GetPagedSharedMediaCommand(
            conversationJid: conversationJid,
            timestamp: newestElement?.timestamp,
            olderThan: false,
          ),
        ) as PagedMessagesResultEvent;

    return result.messages;
  }

  @override
  void dispose() {
    super.dispose();
    BidirectionalSharedMediaController.currentController = null;
  }
}
