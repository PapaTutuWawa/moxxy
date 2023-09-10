import 'dart:async';
import 'dart:io';
import 'package:flutter/widgets.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:logging/logging.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxy_native/moxxy_native.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/constants.dart';
import 'package:moxxyv2/shared/events.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/shared/models/sticker.dart' as sticker;
import 'package:moxxyv2/ui/bloc/conversation_bloc.dart' as conversation;
import 'package:moxxyv2/ui/controller/bidirectional_controller.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

class MessageEditingState {
  const MessageEditingState(
    this.sid,
    this.originalBody,
    this.quoted,
  );

  /// The message's original body
  final String originalBody;

  /// The message's stanza id.
  final String sid;

  /// The message the message quoted
  final Message? quoted;
}

class TextFieldData {
  const TextFieldData(
    this.isBodyEmpty,
    this.quotedMessage,
  );

  /// Flag indicating whether the current text input is empty.
  final bool isBodyEmpty;

  /// The currently quoted message.
  final Message? quotedMessage;
}

class RecordingData {
  const RecordingData(
    this.isRecording,
    this.isLocked,
  );

  /// Flag indicating whether we are currently recording (true) or not (false).
  final bool isRecording;

  /// Flag indicating whether the recording draggable is locked (true) or not (false).
  final bool isLocked;
}

class BidirectionalConversationController
    extends BidirectionalController<Message> {
  BidirectionalConversationController(
    this.conversationJid,
    this.conversationType,
    this.focusNode, {
    String? initialText,
  })  : assert(
          BidirectionalConversationController.currentController == null,
          'There can only be one BidirectionalConversationController',
        ),
        super(
          pageSize: messagePaginationSize,
          maxPageAmount: maxMessagePages,
        ) {
    _textController.addListener(_handleTextChanged);
    if (initialText != null) {
      _textController.text = initialText;
    }

    BidirectionalConversationController.currentController = this;

    _updateChatState(ChatState.active);
  }

  /// Logging.
  final Logger _log = Logger('BidirectionalConversationController');

  /// A singleton referring to the current instance as there can only be one
  /// BidirectionalConversationController at a time.
  static BidirectionalConversationController? currentController;

  /// TextEditingController for the TextField
  final TextEditingController _textController = TextEditingController();
  TextEditingController get textController => _textController;

  /// The focus node of the textfield used for message text input. Useful for
  /// forcing focus after selecting a message for editing.
  final FocusNode focusNode;

  /// Stream for SendButtonState updates
  final StreamController<conversation.SendButtonState>
      _sendButtonStreamController = StreamController();
  Stream<conversation.SendButtonState> get sendButtonStream =>
      _sendButtonStreamController.stream;

  /// The JID of the current chat
  final String conversationJid;

  /// The type of the current conversation
  final String conversationType;

  /// Data about a message we're editing
  MessageEditingState? _messageEditingState;

  /// Flag indicating whether we are scrolled to the bottom or not.
  bool _scrolledToBottomState = true;
  final StreamController<bool> _scrollToBottomStateStreamController =
      StreamController();
  Stream<bool> get scrollToBottomStateStream =>
      _scrollToBottomStateStreamController.stream;

  /// The currently quoted message
  Message? _quotedMessage;

  /// Stream containing data for the TextField
  final StreamController<TextFieldData> _textFieldDataStreamController =
      StreamController();
  Stream<TextFieldData> get textFieldDataStream =>
      _textFieldDataStreamController.stream;

  /// The timer for managing the "compose" state
  Timer? _composeTimer;

  /// The last time the TextField was modified
  int _lastChangeTimestamp = 0;

  /// Flag indicating whether we are currently recording an audio message (true) or not
  /// (false).
  final Record _audioRecorder = Record();
  DateTime? _recordingStart;
  final StreamController<RecordingData> _recordingAudioMessageStreamController =
      StreamController<RecordingData>.broadcast();
  Stream<RecordingData> get recordingAudioMessageStream =>
      _recordingAudioMessageStreamController.stream;

  void _updateChatState(ChatState state) {
    getForegroundService().send(
          SendChatStateCommand(
            state: state.toString().split('.').last,
            jid: conversationJid,
            conversationType: conversationType,
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

  void _handleTextChanged() {
    final text = _textController.text;
    if (_messageEditingState != null) {
      _sendButtonStreamController.add(
        text == _messageEditingState?.originalBody
            ? conversation.SendButtonState.cancelCorrection
            : conversation.SendButtonState.send,
      );
    } else {
      _sendButtonStreamController.add(
        text.isEmpty
            ? conversation.defaultSendButtonState
            : conversation.SendButtonState.send,
      );
    }

    _textFieldDataStreamController.add(
      TextFieldData(
        messageBody.isEmpty,
        _quotedMessage,
      ),
    );

    _lastChangeTimestamp = DateTime.now().millisecondsSinceEpoch;
    _startComposeTimer();
  }

  @override
  void handleScroll() {
    super.handleScroll();

    if (isScrolledToBottom && !_scrolledToBottomState && !hasNewerData) {
      _scrolledToBottomState = true;
      _scrollToBottomStateStreamController.add(false);
    } else if (!isScrolledToBottom && _scrolledToBottomState) {
      _scrolledToBottomState = false;
      _scrollToBottomStateStreamController.add(true);
    }
  }

  String get messageBody => _textController.text;

  Future<void> onMessageReceived(Message message) async {
    // Drop the message if we don't really care about it
    if (message.conversationJid != conversationJid) {
      _log.finest(
        "Not processing message as JIDs don't match: ${message.conversationJid} != $conversationJid",
      );
      return;
    }

    // TODO(Unknown): This is probably not the best solution
    if (isFetching) {
      _log.finest('Not processing message as we are currently fetching');
      return;
    }

    var shouldScrollToBottom = true;
    if (cache.isEmpty && hasFetchedOnce) {
      // We do this check here to prevent a StateException being thrown because
      // the cache is empty. So just add the message.
      addItem(message);

      // As this is the first message, we don't have to scroll to the bottom.
      shouldScrollToBottom = false;
    } else if (message.timestamp < cache.last.timestamp) {
      if (message.timestamp < cache.first.timestamp) {
        // The message is older than the oldest message we know about. Drop it.
        // It will be fetched when scrolling up.
        hasOlderData = true;
        return;
      }

      // Insert the message at the appropriate place
      shouldScrollToBottom = addItemWhereFirst(
        (item, next) {
          if (next == null) return false;

          return item.timestamp <= message.timestamp &&
              next.timestamp >= message.timestamp;
        },
        message,
      );
    } else {
      // Just add the new message
      addItem(message);
    }

    // Scroll to bottom if we're at the bottom
    if (isScrolledToBottom && shouldScrollToBottom) {
      await Future<void>.delayed(const Duration(milliseconds: 300));
      animateToBottom();
    }
  }

  void onMessageUpdated(Message newMessage) {
    // Ignore message updates for messages in chats that are not open.
    if (newMessage.conversationJid != conversationJid) return;

    // Ignore message updates for messages older than the oldest message
    // we know about.
    if (newMessage.timestamp < cache.first.timestamp) return;

    replaceItem(
      (msg) => msg.id == newMessage.id,
      newMessage,
    );
  }

  /// Retract the message with originId [originId].
  void retractMessage(String originId) {
    getForegroundService().send(
          RetractMessageCommentCommand(
            originId: originId,
            conversationJid: conversationJid,
          ),
          awaitable: false,
        );
  }

  /// Send the sticker [sticker].
  void sendSticker(sticker.Sticker sticker) {
    getForegroundService().send(
          SendStickerCommand(
            sticker: sticker,
            recipient: conversationJid,
            quotes: _quotedMessage,
          ),
          awaitable: false,
        );

    // Remove a possible quote
    removeQuote();
  }

  Future<void> sendMessage(bool encrypted) async {
    // Stop the compose timer
    _stopComposeTimer();

    // Reset the text field
    final text = _textController.text;
    assert(text.isNotEmpty, 'Cannot send empty text messages');
    _textController.text = '';

    // Add message to the database and send it
    // ignore: cast_nullable_to_non_nullable
    final result = await getForegroundService().send(
          SendMessageCommand(
            recipients: [conversationJid],
            body: text,
            quotedMessage: _quotedMessage,
            chatState: ChatState.active.toName(),
            editSid: _messageEditingState?.sid,
            currentConversationJid: conversationJid,
          ),
          awaitable: true,
        ) as MessageAddedEvent;

    // Reset the message editing state
    final wasEditing = _messageEditingState != null;
    _messageEditingState = null;

    // Reset the quote
    removeQuote();

    var foundMessage = false;
    if (!hasNewerData) {
      if (wasEditing) {
        foundMessage = replaceItem(
          (message) => message.id == result.message.id,
          result.message,
        );
      } else {
        addItem(result.message);
        foundMessage = false;
      }

      if (foundMessage) {
        await Future<void>.delayed(const Duration(milliseconds: 300));
        animateToBottom();
      }
    } else {
      // TODO(PapaTutuWawa): Load the newest page and scroll to it
    }
  }

  @override
  Future<List<Message>> fetchOlderDataImpl(Message? oldestElement) async {
    // ignore: cast_nullable_to_non_nullable
    final result = await getForegroundService().send(
          GetPagedMessagesCommand(
            conversationJid: conversationJid,
            timestamp: oldestElement?.timestamp,
            olderThan: true,
          ),
        ) as PagedMessagesResultEvent;

    return result.messages.reversed.toList();
  }

  @override
  Future<List<Message>> fetchNewerDataImpl(Message? newestElement) async {
    // ignore: cast_nullable_to_non_nullable
    final result = await getForegroundService().send(
          GetPagedMessagesCommand(
            conversationJid: conversationJid,
            timestamp: newestElement?.timestamp,
            olderThan: false,
          ),
        ) as PagedMessagesResultEvent;

    return result.messages.reversed.toList();
  }

  /// Quote [message] for a message.
  void quoteMessage(Message message) {
    _quotedMessage = message;
    _textFieldDataStreamController.add(
      TextFieldData(
        messageBody.isEmpty,
        message,
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
      ),
    );
  }

  /// Enter the "edit mode" for a message.
  void beginMessageEditing(
    String originalBody,
    Message? quotes,
    String sid,
  ) {
    _log.fine('Beginning editing for $sid');

    _messageEditingState = MessageEditingState(
      sid,
      originalBody,
      quotes,
    );
    _textController.text = originalBody;
    if (quotes != null) {
      quoteMessage(quotes);
    }

    _sendButtonStreamController
        .add(conversation.SendButtonState.cancelCorrection);

    // Focus the textfield.
    focusNode.requestFocus();
  }

  /// Exit the "edit mode" for a message.
  void endMessageEditing() {
    _messageEditingState = null;
    _textController.text = '';

    _sendButtonStreamController.add(conversation.defaultSendButtonState);
  }

  Future<void> startAudioMessageRecording() async {
    final status = await Permission.speech.status;
    if (status.isDenied) {
      await Permission.speech.request();
      return;
    }

    _recordingAudioMessageStreamController.add(
      const RecordingData(
        true,
        false,
      ),
    );
    _sendButtonStreamController.add(conversation.SendButtonState.hidden);

    final now = DateTime.now();
    _recordingStart = now;
    final tempDir = await getTemporaryDirectory();
    final timestamp =
        '${now.year}${now.month}${now.day}${now.hour}${now.minute}${now.second}';
    final tempFile = path.join(tempDir.path, 'audio_$timestamp.aac');
    await _audioRecorder.start(
      path: tempFile,
    );
  }

  void lockAudioMessageRecording() {
    _recordingAudioMessageStreamController.add(
      const RecordingData(
        true,
        true,
      ),
    );
  }

  Future<void> cancelAudioMessageRecording() async {
    Vibrate.feedback(FeedbackType.heavy);
    _recordingAudioMessageStreamController.add(
      const RecordingData(
        false,
        false,
      ),
    );
    _sendButtonStreamController.add(conversation.defaultSendButtonState);

    _recordingStart = null;
    final file = await _audioRecorder.stop();
    unawaited(File(file!).delete());
  }

  Future<void> endAudioMessageRecording() async {
    _recordingAudioMessageStreamController.add(
      const RecordingData(
        false,
        false,
      ),
    );
    _sendButtonStreamController.add(conversation.defaultSendButtonState);

    if (_recordingStart == null) {
      return;
    }

    Vibrate.feedback(FeedbackType.heavy);
    final file = await _audioRecorder.stop();
    final now = DateTime.now();
    if (now.difference(_recordingStart!).inSeconds < 1) {
      _recordingStart = null;
      unawaited(File(file!).delete());
      await Fluttertoast.showToast(
        msg: t.warnings.conversation.holdForLonger,
        gravity: ToastGravity.SNACKBAR,
        toastLength: Toast.LENGTH_SHORT,
      );
      return;
    }

    // Reset the recording timestamp
    _recordingStart = null;

    // Handle something unexpected
    if (file == null) {
      await Fluttertoast.showToast(
        msg: t.errors.conversation.audioRecordingError,
        gravity: ToastGravity.SNACKBAR,
        toastLength: Toast.LENGTH_SHORT,
      );
      return;
    }

    // Send the file
    await getForegroundService().send(
          SendFilesCommand(
            paths: [file],
            recipients: [conversationJid],
          ),
          awaitable: false,
        );
  }

  /// React to app livecycle changes
  void handleAppStateChange(bool open) {
    _updateChatState(
      open ? ChatState.active : ChatState.gone,
    );
  }

  @override
  void dispose() {
    // Reset the singleton
    BidirectionalConversationController.currentController = null;

    // Dispose of controllers
    _textController.dispose();
    _audioRecorder.dispose();

    super.dispose();
  }
}
