import 'dart:async';
import 'package:flutter/animation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxplatform/moxplatform.dart';
import 'package:moxxyv2/ui/bloc/conversation_bloc.dart' as conversation;
import 'package:moxxyv2/ui/service/data.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/constants.dart';
import 'package:moxxyv2/shared/models/message.dart';

class MessageEditingState {
  const MessageEditingState(
    this.id,
    this.sid,
    this.originalBody,
    this.quoted,
  );

  /// The message's original body
  final String originalBody;

  /// The message's database id
  final int id;

  /// The message's stanza id.
  final String sid;

  /// The message the message quoted
  final Message? quoted;
}

class TextFieldData {
  const TextFieldData(
    this.isBodyEmpty,
    this.quotedMessage,
    this.pickerVisible,
  );

  /// Flag indicating whether the current text input is empty.
  final bool isBodyEmpty;

  /// The currently quoted message.
  final Message? quotedMessage;

  /// Flag indicating whether the picker is currently open or not.
  final bool pickerVisible;
}

class BidirectionalConversationController {
  BidirectionalConversationController(this.conversationJid) {
    assert(BidirectionalConversationController.currentController == null, 'There can only be one BidirectionalConversationController');

    _scrollController.addListener(_handleScroll);
    _textController.addListener(_handleTextChanged);
    _keyboardVisibilitySubscription = KeyboardVisibilityController().onChange.listen(_handleSoftKeyboardVisibilityChanged);

    BidirectionalConversationController.currentController = this;

    _updateChatState(ChatState.active);
  }

  /// A singleton referring to the current instance as there can only be one
  /// BidirectionalConversationController at a time.
  static BidirectionalConversationController? currentController;
  
  late final StreamSubscription _keyboardVisibilitySubscription;
  
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
  final ScrollController _scrollController = ScrollController();
  ScrollController get scrollController => _scrollController;

  /// Stream for message updates
  final StreamController<List<Message>> _messageStreamController = StreamController();
  Stream<List<Message>> get messageStream => _messageStreamController.stream;

  /// TextEditingController for the TextField
  final TextEditingController _textController = TextEditingController();
  TextEditingController get textController => _textController;

  /// Stream for SendButtonState updates
  final StreamController<conversation.SendButtonState> _sendButtonStreamController = StreamController();
  Stream<conversation.SendButtonState> get sendButtonStream => _sendButtonStreamController.stream;

  /// The JID of the current chat
  final String conversationJid;

  /// Data about a message we're editing
  MessageEditingState? _messageEditingState;

  /// Flag indicating whether we are scrolled to the bottom or not.
  bool _scrolledToBottomState = true;
  final StreamController<bool> _scrollToBottomStateStreamController = StreamController();
  Stream<bool> get scrollToBottomStateStream => _scrollToBottomStateStreamController.stream;

  /// The currently quoted message
  Message? _quotedMessage;

  /// Stream containing data for the TextField
  final StreamController<TextFieldData> _textFieldDataStreamController = StreamController();
  Stream<TextFieldData> get textFieldDataStream => _textFieldDataStreamController.stream;

  /// Flag indicating whether the (emoji/sticker) picker is visible
  bool _pickerVisible = false;
  final StreamController<bool> _pickerVisibleStreamController = StreamController.broadcast();
  Stream<bool> get pickerVisibleStream => _pickerVisibleStreamController.stream;

  /// The timer for managing the "compose" state
  Timer? _composeTimer;

  /// The last time the TextField was modified
  int _lastChangeTimestamp = 0;

  void _updateChatState(ChatState state) {
    MoxplatformPlugin.handler.getDataSender().sendData(
      SendChatStateCommand(
        state: state.toString().split('.').last,
        jid: conversationJid,
      ),
      awaitable: false,
    );
  }
  
  void _startComposeTimer() {
    if (_composeTimer != null) return;

    _updateChatState(ChatState.composing);
    _composeTimer = Timer.periodic(
      const Duration(seconds: 3),
      (_) {
        final now = DateTime.now().millisecondsSinceEpoch;
        if (now - _lastChangeTimestamp >= 3000) {
          // No change since 3 seconds
          _stopComposeTimer();
          _updateChatState(ChatState.active);
        }
      },
    );
  }

  void _stopComposeTimer() {
    if (_composeTimer == null) return;

    _composeTimer?.cancel();
    _composeTimer = null;
  }
  
  void _handleSoftKeyboardVisibilityChanged(bool visible) {
    if (visible && _pickerVisible) {
      togglePickerVisibility(false);
    }
  }
  
  void _handleTextChanged() {
    final text = _textController.text;
    if (_messageEditingState != null) {
      _sendButtonStreamController.add(
        text == _messageEditingState?.originalBody ?
          conversation.SendButtonState.cancelCorrection :
          conversation.SendButtonState.send,
      );
    } else {
      _sendButtonStreamController.add(
        text.isEmpty ?
          conversation.defaultSendButtonState :
          conversation.SendButtonState.send,
      );
    }

    _textFieldDataStreamController.add(
      TextFieldData(
        messageBody.isEmpty,
        _quotedMessage,
        _pickerVisible,
      ),
    );

    _lastChangeTimestamp = DateTime.now().millisecondsSinceEpoch;
    _startComposeTimer();
  }
  
  void _setIsFetching(bool state) {
    isFetchingMessages = state;
    _isFetchingStreamController.add(state);
  }

  /// Taken from https://bloclibrary.dev/#/flutterinfinitelisttutorial
  bool _isScrolledToBottom() {
    return _scrollController.offset <= 10;
  }
  
  void _handleScroll() {
    if (!_scrollController.hasClients) return;

    // Fetch older messages when we reach the top edge of the list
    // TODO(Unknown): Do not hide the scroll to bottom button unless we are on the
    //                last page.
    if (_scrollController.offset >= _scrollController.position.maxScrollExtent - 20 && !isFetchingMessages) {
      unawaited(fetchOlderMessages());
    } else if (_isScrolledToBottom() && !_scrolledToBottomState) {
      _scrolledToBottomState = true;
      _scrollToBottomStateStreamController.add(false);
    } else if (!_isScrolledToBottom() && _scrolledToBottomState) {
      _scrolledToBottomState = false;
      _scrollToBottomStateStreamController.add(true);
    }
  }

  String get messageBody => _textController.text;
  
  void animateToBottom() {
    _scrollController.animateTo(
      _scrollController.position.minScrollExtent,
      curve: Curves.easeIn,
      duration: const Duration(milliseconds: 300),
    );
  }

  Future<void> onMessageReceived(Message message) async {
    // Drop the message if we don't really care about it
    if (message.conversationJid != conversationJid) return;

    if (message.timestamp < _messageCache.last.timestamp) {
      if (message.timestamp < _messageCache.first.timestamp) {
        // The message is older than the oldest message we know about. Drop it.
        // It will be fetched when scrolling up.
        hasOlderMessages = true;
        return;
      }

      // TODO: Correctly insert the message
    }

    // Notify the UI
    _messageCache.add(message);
    _messageStreamController.add(_messageCache);

    // Scroll to bottom if we're at the bottom
    if (_isScrolledToBottom()) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      animateToBottom();
    }
  }

  void onMessageUpdated(Message newMessage) {
    // Ignore message updates for messages in chats that are not open.
    if (newMessage.conversationJid != conversationJid) return;

    // Ignore message updates for messages older than the oldest message
    // we know about.
    if (newMessage.timestamp < _messageCache.first.timestamp) return;

    // We iterate in reverse as we can assume that the newer messages have a higher
    // likeliness of being updated than older messages.
    var messageFound = false;
    for (var i = _messageCache.length - 1; i >= 0; i--) {
      if (_messageCache[i].id == newMessage.id) {
        _messageCache[i] = newMessage;
        messageFound = true;
        break;
      }
    }

    if (messageFound) {
      _messageStreamController.add(_messageCache);
    }
  }

  /// Retract the message with originId [originId].
  void retractMessage(String originId) {
    MoxplatformPlugin.handler.getDataSender().sendData(
      RetractMessageCommentCommand(
        originId: originId,
        conversationJid: conversationJid,
      ),
      awaitable: false,
    );
  }
  
  Future<void> sendMessage(bool encrypted) async {
    // Stop the compose timer
    _stopComposeTimer();

    // Reset the text field
    final text = _textController.text;
    assert(text.isNotEmpty, 'Cannot send empty text messages');
    _textController.text = '';

    // Reset the message editing state
    final wasEditing = _messageEditingState != null;
    _messageEditingState = null;

    // Add message to the database and send it
    // ignore: cast_nullable_to_non_nullable
    final result = await MoxplatformPlugin.handler.getDataSender().sendData(
      SendMessageCommand(
        recipients: [conversationJid],
        body: text,
        quotedMessage: _quotedMessage,
        chatState: chatStateToString(ChatState.active),
        editId: _messageEditingState?.id,
        editSid: _messageEditingState?.sid,
        currentConversationJid: conversationJid,
      ),
      awaitable: true,
    ) as MessageAddedEvent;
    
    if (!hasNewerMessages) {
      if (wasEditing) {
        // TODO: Handle
      } else {
        _messageCache.add(result.message);
      }

      _messageStreamController.add(_messageCache);
      
      await Future<void>.delayed(const Duration(milliseconds: 300));
      animateToBottom();
    } else {
      // TODO(PapaTutuWawa): Load the newest page and scroll to it
    }

    _sendButtonStreamController.add(conversation.defaultSendButtonState);
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

  /// Quote [message] for a message.
  void quoteMessage(Message message) {
    _quotedMessage = message;
    _textFieldDataStreamController.add(
      TextFieldData(
        messageBody.isEmpty,
        message,
        _pickerVisible,
      ),
    );
  }

  /// Remove the currently active quote.
  void removeQuote() {
    _quotedMessage = null;
    _textFieldDataStreamController.add(
      TextFieldData(
        messageBody.isEmpty,
        null,
        _pickerVisible,
      ),
    );
  }
  
  /// Enter the "edit mode" for a message.
  void beginMessageEditing(String originalBody, Message? quotes, int id, String sid) {
    _messageEditingState = MessageEditingState(
      id,
      sid,
      originalBody,
      quotes,
    );
    _textController.text = originalBody;
    if (quotes != null) {
      quoteMessage(quotes);
    }

    _sendButtonStreamController.add(conversation.SendButtonState.cancelCorrection);
  }

  /// Exit the "edit mode" for a message.
  void endMessageEditing() {
    _messageEditingState = null;
    _textController.text = '';

    _sendButtonStreamController.add(conversation.defaultSendButtonState);
  }

  /// Toggles the visibility of the (emoji/sticker) picker
  void togglePickerVisibility(bool handleKeyboard) {
    final newState = !_pickerVisible;

    if (handleKeyboard) {
      if (newState) {
        SystemChannels.textInput.invokeMethod('TextInput.hide');
      } else {
        SystemChannels.textInput.invokeMethod('TextInput.show');
      }
    }

    _pickerVisible = newState;
    _pickerVisibleStreamController.add(newState);
    _textFieldDataStreamController.add(
      TextFieldData(
        messageBody.isEmpty,
        _quotedMessage,
        newState,
      ),
    );
  }

  /// React to a onWillPop callback.
  bool handlePop() {
    if (_pickerVisible) {
      togglePickerVisibility(false);
      return false;
    }

    return true;
  }

  /// React to app livecycle changes
  void handleAppStateChange(bool open) {
    _updateChatState(
      open ?
        ChatState.active :
        ChatState.gone,
    );
  }
  
  void dispose() {
    BidirectionalConversationController.currentController = null;

    _updateChatState(ChatState.gone);
    
    _scrollController.dispose();
    _textController.dispose();
    _keyboardVisibilitySubscription.cancel();
  }
}
