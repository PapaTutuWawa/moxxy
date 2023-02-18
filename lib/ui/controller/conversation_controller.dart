import 'dart:async';
import 'package:flutter/animation.dart';
import 'package:flutter/widgets.dart';
import 'package:moxplatform/moxplatform.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/constants.dart';
import 'package:moxxyv2/shared/models/message.dart';

class BidirectionalConversationController {
  BidirectionalConversationController(this.conversationJid) {
    _controller.addListener(_handleScroll);
  }

  /// The list of messages we know about
  final List<Message> _messageCache = List<Message>.empty(growable: true);

  /// Flag indicating whether we are currently fetching messages.
  bool isFetchingMessages = false;
  final StreamController<bool> _isFetchingStreamController = StreamController();
  Stream<bool> get isFetchingStream => _isFetchingStreamController.stream;

  /// Flag indicating whether we have newer messages we could request from the database
  bool hasNewerMessages = false;

  /// Flag indicating whether we have older messages we could request from the database
  bool hasOlderMessages = true;

  /// Flag indicating whether messages have been fetched once
  bool hasFetchedOnce = false;
  
  /// Scroll controller for managing things like loading newer and older messages
  final ScrollController _controller = ScrollController();
  ScrollController get scrollController => _controller;

  /// Stream for message updates
  final StreamController<List<Message>> _messageStreamController = StreamController();
  Stream<List<Message>> get messageStream => _messageStreamController.stream;

  /// The JID of the current chat
  final String conversationJid;

  void _setIsFetching(bool state) {
    isFetchingMessages = state;
    _isFetchingStreamController.add(state);
  }
  
  void _handleScroll() {
    if (!_controller.hasClients) return;

    // Fetch older messages when we reach the top edge of the list
    if (_controller.offset >= _controller.position.maxScrollExtent - 20 && !isFetchingMessages) {
      unawaited(fetchOlderMessages());
    }
  }
  
  void animateToBottom() {
    _controller.animateTo(
      _controller.position.minScrollExtent,
      curve: Curves.easeIn,
      duration: const Duration(milliseconds: 300),
    );
  }
  
  void onMessageSent(Message message) {
    if (hasNewerMessages) {
      _messageCache.add(message);

      _messageStreamController.add(_messageCache);
      
      Future<void>.delayed(const Duration(milliseconds: 300))
        .then((_) => animateToBottom());
    } else {
      // TODO(PapaTutuWawa): Load the newest page and scroll to it
    }
  }

  Future<void> fetchOlderMessages() async {
    if (isFetchingMessages ||
        _messageCache.isEmpty && hasFetchedOnce) return;
    if (!hasOlderMessages) return;

    _setIsFetching(true);

    // ignore: cast_nullable_to_non_nullable
    final result = await MoxplatformPlugin.handler.getDataSender().sendData(
      GetPagedMessagesCommand(
        conversationJid: conversationJid,
        oldestMessageTimestamp: !hasFetchedOnce ?
          null :
          _messageCache.first.timestamp,
      ),
    ) as PagedMessagesResultEvent;

    _setIsFetching(false);
    hasFetchedOnce = true;
    hasOlderMessages = result.hasOlderMessages;

    if (result.messages.length == 0) {
      hasOlderMessages = false;
      return;
    } else if (result.messages.length < paginatedMessageFetchAmount) {
      // This means we reached the end of messages we can fetch
      hasOlderMessages = false;
    }

    _messageCache.insertAll(0, result.messages.reversed);
    _messageStreamController.add(_messageCache);
  }
  
  void dispose() {
    _controller.dispose();
  }
}
