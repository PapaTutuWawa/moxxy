import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:get_it/get_it.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:mime/mime.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxy_native/moxxy_native.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/shared/models/conversation.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/ui/bloc/conversation_bloc.dart';
import 'package:moxxyv2/ui/bloc/conversations_bloc.dart';
import 'package:moxxyv2/ui/bloc/sendfiles_bloc.dart';
import 'package:moxxyv2/ui/controller/conversation_controller.dart';
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/ui/pages/conversation/helpers.dart';
import 'package:moxxyv2/ui/pages/conversation/keyboard_dodging.dart';
import 'package:moxxyv2/ui/pages/conversation/selected_message.dart';
import 'package:moxxyv2/ui/pages/conversation/topbar.dart';
import 'package:moxxyv2/ui/service/data.dart';
import 'package:moxxyv2/ui/service/read.dart';
import 'package:moxxyv2/ui/theme.dart';
import 'package:moxxyv2/ui/widgets/chat/bubbles/bubbles.dart';
import 'package:moxxyv2/ui/widgets/chat/bubbles/date.dart';
import 'package:moxxyv2/ui/widgets/chat/chatbubble.dart';
import 'package:moxxyv2/ui/widgets/chat/typing_indicator.dart';
import 'package:moxxyv2/ui/widgets/combined_picker.dart';
import 'package:moxxyv2/ui/widgets/context_menu.dart';
import 'package:moxxyv2/ui/widgets/messaging_textfield/messaging_textfield.dart';
import 'package:path/path.dart' as path;
import 'package:uuid/uuid.dart';

class ConversationPageArguments {
  const ConversationPageArguments(
    this.conversationJid,
    this.initialText,
    this.type,
  );

  final String conversationJid;

  final String? initialText;

  final ConversationType type;
}

int getMessageMenuOptionCount(
  Message message,
  Message? lastMessage,
  bool sentBySelf,
) {
  return [
    message.isReactable,
    message.canRetract(sentBySelf),
    // TODO(Unknown): Remove this and just allow us to correct any message
    message.canEdit(sentBySelf) && lastMessage?.id == message.id,
    message.errorMenuVisible,
    message.hasWarning,
    message.isCopyable,
    message.isQuotable && message.conversationJid != '',
    message.isQuotable,
  ].where((r) => r).length;
}

class ConversationPage extends StatefulWidget {
  const ConversationPage({
    required this.conversationJid,
    required this.conversationType,
    this.initialText,
    super.key,
  });

  /// The JID of the current conversation
  final String conversationJid;

  /// The optional initial text to put in the input field.
  final String? initialText;

  /// The type of the conversation.
  final ConversationType conversationType;

  @override
  ConversationPageState createState() => ConversationPageState();
}

class ConversationPageState extends State<ConversationPage>
    with TickerProviderStateMixin {
  /// Controllers and data for the bottom input field
  late final BidirectionalConversationController _conversationController;
  late final TabController _tabController;
  final KeyboardReplacerController _keyboardController =
      KeyboardReplacerController();
  final ValueNotifier<bool> _speedDialValueNotifier = ValueNotifier(false);
  final FocusNode _textfieldFocusNode = FocusNode();

  /// Controllers, animation, and state for the selection animation
  late final AnimationController _selectionAnimationController;
  late final Animation<double> _selectionAnimation;
  late final SelectedMessageController _selectionController;

  /// Controllers and state for the "scroll to bottom" animation
  late final AnimationController _scrollToBottomAnimationController;
  late final Animation<double> _scrollToBottomAnimation;
  late final StreamSubscription<bool> _scrolledToBottomStateSubscription;

  final Map<String, GlobalKey> _messageKeys = {};

  @override
  void initState() {
    super.initState();

    // Setup message paging
    _conversationController = BidirectionalConversationController(
      widget.conversationJid,
      widget.conversationType,
      _textfieldFocusNode,
      initialText: widget.initialText,
    );
    _conversationController.fetchOlderData();

    // Tabbing inside the combined picker
    _tabController = TabController(
      length: 2,
      vsync: this,
    );

    // Animations for the message selection
    _selectionAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _selectionAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _selectionAnimationController,
        curve: Curves.easeInOutCubic,
      ),
    );
    _selectionController = SelectedMessageController(
      _selectionAnimationController,
      _selectionAnimation,
    );

    // Animation for the "scroll to bottom" button
    _scrollToBottomAnimationController = AnimationController(
      duration: const Duration(milliseconds: 180),
      vsync: this,
    );
    _scrollToBottomAnimation = CurvedAnimation(
      parent: _scrollToBottomAnimationController,
      curve: const Interval(0.5, 1),
    );
    _scrolledToBottomStateSubscription = _conversationController
        .scrollToBottomStateStream
        .listen(_onScrollToBottomStateChanged);
  }

  @override
  void dispose() {
    // Controllers
    _tabController.dispose();
    _conversationController.dispose();
    _keyboardController.dispose();

    // Selection animation
    _selectionAnimationController.dispose();

    // Scroll to bottom animation
    _scrollToBottomAnimationController.dispose();
    _scrolledToBottomStateSubscription.cancel();
    super.dispose();
  }

  /// Called when we should show or hide the "scroll to bottom" button.
  void _onScrollToBottomStateChanged(bool state) {
    if (state) {
      _scrollToBottomAnimationController.forward();
    } else {
      _scrollToBottomAnimationController.reverse();
    }
  }

  /// Render a widget that allows the user to either block the user or add them to their
  /// roster
  Widget _renderNotInRosterWidget(
    ConversationState state,
    BuildContext context,
  ) {
    return ColoredBox(
      color: Colors.black38,
      child: SizedBox(
        height: 64,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: TextButton(
                child: Text(
                  t.pages.conversation.addToContacts,
                  style: TextStyle(
                    color: Theme.of(context)
                        .extension<MoxxyThemeData>()!
                        .conversationTextFieldTextColor,
                  ),
                ),
                onPressed: () async {
                  final jid = state.conversation!.jid;
                  final result = await showConfirmationDialog(
                    t.pages.conversation.addToContactsTitle(jid: jid),
                    t.pages.conversation.addToContactsBody(jid: jid),
                    context,
                  );

                  if (result) {
                    // ignore: use_build_context_synchronously
                    context.read<ConversationBloc>().add(
                          JidAddedEvent(jid),
                        );
                  }
                },
              ),
            ),
            Expanded(
              child: TextButton(
                child: Text(
                  t.pages.conversation.blockShort,
                  style: TextStyle(
                    color: Theme.of(context)
                        .extension<MoxxyThemeData>()!
                        .conversationTextFieldTextColor,
                  ),
                ),
                onPressed: () => blockJid(state.conversation!.jid, context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Take a message and render it into a widget.
  Widget _renderBubble(
    ConversationState state,
    Message message,
    List<Message> messages,
    int index,
    double maxWidth,
  ) {
    final item = message;

    if (item.isPseudoMessage) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
            ),
            child: bubbleFromPseudoMessageType(context, item),
          ),
        ],
      );
    }

    final ownJid = GetIt.I.get<UIDataService>().ownJid!;
    final start = index - 1 < 0
        ? true
        : isSent(messages[index - 1], ownJid) != isSent(item, ownJid);
    final end = index + 1 >= messages.length
        ? true
        : isSent(messages[index + 1], ownJid) != isSent(item, ownJid);
    final between = !start && !end;
    final sentBySelf = isSent(message, ownJid);

    // Give each bubble its own animation and animation controller
    GlobalKey key;
    if (!_messageKeys.containsKey(item.id)) {
      key = GlobalKey();
      _messageKeys[item.id] = key;
    } else {
      key = _messageKeys[item.id]!;
    }

    final bubble = RawChatBubble(
      item,
      maxWidth,
      sentBySelf,
      state.conversation!.encrypted,
      start,
      between,
      end,
      state.conversation!.isGroupchat,
      key: key,
    );

    return ChatBubble(
      bubble: bubble,
      message: item,
      sentBySelf: sentBySelf,
      maxWidth: maxWidth,
      onSwipedCallback: _conversationController.quoteMessage,
      onLongPressed: (event) async {
        if (!message.isLongpressable) {
          return;
        }

        Vibrate.feedback(FeedbackType.medium);

        // Get the position of the message on screen
        final widgetRect = getWidgetPositionOnScreen(key);

        // Figure out how many overview items we'll be showing
        final overviewMenuItemCount = getMessageMenuOptionCount(
          item,
          state.conversation?.lastMessage,
          sentBySelf,
        );

        // Dismiss the soft-keyboard
        dismissSoftKeyboard(context);

        // Start the actual animation
        _selectionController.selectMessage(
          SelectedMessageData(
            item,
            state.conversation?.isGroupchat ?? false,
            state.conversation?.encrypted ?? false,
            sentBySelf,
            Offset(
              widgetRect.topLeft.dx,
              widgetRect.topLeft.dy,
            ),

            // Compute how much we have to move the widget in order to be 20 units above
            // the overview menu, which is always 20 units + height away from the bottom.
            MediaQuery.of(context).size.height -
                widgetRect.bottom -
                20 -
                overviewMenuItemCount * ContextMenuItem.height -
                20,

            start,
            between,
            end,
          ),
        );
      },
      visibilityCallback: (info) {
        if (sentBySelf) return;

        if (info.visibleFraction >= 0) {
          GetIt.I.get<UIReadMarkerService>().handleMarker(message);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.6;
    return WillPopScope(
      onWillPop: () async {
        if (_keyboardController.currentData.visible) {
          // If the keyboard is open, dismiss it.
          dismissSoftKeyboard(context);
          return false;
        } else if (_keyboardController.currentData.showWidget) {
          // If the emoji/sticker picker is open, dismiss it.
          _keyboardController.hideWidget();
          _textfieldFocusNode.unfocus();
          return false;
        } else if (_conversationController
            .messagingController.isRecordingNotifier.value) {
          // If we are recording a voice message, ask if we should continue or discard it.
          final result = await showConfirmationDialog(
            t.pages.conversation.voiceRecording.leaveConfirmation.title,
            t.pages.conversation.voiceRecording.leaveConfirmation.body,
            context,
            affirmativeText: t.pages.conversation.voiceRecording
                .leaveConfirmation.affirmative,
            negativeText:
                t.pages.conversation.voiceRecording.leaveConfirmation.negative,
          );
          if (!result) {
            return false;
          }

          // Cancel the recording
          _conversationController.messagingController.cancelRecording();
        }

        // Clear the read marker cache
        GetIt.I.get<UIReadMarkerService>().clear();

        // Tell the backend that the chat is no longer open
        GetIt.I.get<ConversationsBloc>().add(
              ConversationExitedEvent(
                widget.conversationType,
              ),
            );
        return true;
      },
      child: KeyboardReplacerScaffold(
        controller: _keyboardController,
        keyboardWidget: CombinedPicker(
          tabController: _tabController,
          onEmojiTapped: (emoji) {
            final selection = _conversationController.textController.selection;
            final baseOffset = max(selection.baseOffset, 0);
            final extentOffset = max(selection.extentOffset, 0);
            final prefix =
                _conversationController.messageBody.substring(0, baseOffset);
            final suffix =
                _conversationController.messageBody.substring(extentOffset);
            final newText = '$prefix${emoji.emoji}$suffix';
            final newValue = baseOffset + emoji.emoji.codeUnits.length;
            _conversationController.textController
              ..text = newText
              ..selection = TextSelection(
                baseOffset: newValue,
                extentOffset: newValue,
              );
          },
          onBackspaceTapped: () {
            // Taken from https://github.com/Fintasys/emoji_picker_flutter/blob/master/lib/src/emoji_picker.dart#L183
            final text = _conversationController.messageBody;
            final selection = _conversationController.textController.selection;
            final cursorPosition =
                _conversationController.textController.selection.base.offset;

            if (cursorPosition < 0) {
              return;
            }

            final newTextBeforeCursor =
                selection.textBefore(text).characters.skipLast(1).toString();

            _conversationController.textController
              ..text = newTextBeforeCursor
              ..selection = TextSelection.fromPosition(
                TextPosition(offset: newTextBeforeCursor.length),
              );
          },
          onStickerTapped: (sticker) {
            _conversationController.sendSticker(
              sticker,
            );
            _keyboardController.hideWidget();
          },
        ),
        appbar: const ConversationTopbar(),
        extraStackChildren: [
          // The skim behind the context menu items
          AnimatedBuilder(
            animation: _selectionAnimation,
            builder: (context, _) => Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: Visibility(
                visible: _selectionAnimation.value != 0,
                child: IgnorePointer(
                  ignoring: _selectionAnimation.value == 0,
                  child: GestureDetector(
                    onTap: _selectionController.dismiss,
                    child: Container(
                      color: Colors.black
                          .withOpacity(0.6 * _selectionAnimation.value),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // The selected message
          SelectedMessage(_selectionController),

          // The context menu
          SelectedMessageContextMenu(
            selectionController: _selectionController,
            conversationController: _conversationController,
          ),
        ],
        background: BlocBuilder<ConversationBloc, ConversationState>(
          buildWhen: (prev, next) => prev.backgroundPath != next.backgroundPath,
          builder: (context, state) {
            final query = MediaQuery.of(context);

            if (state.backgroundPath != null) {
              return Image.file(
                File(state.backgroundPath!),
                fit: BoxFit.cover,
                width: query.size.width,
                height: query.size.height - query.padding.top,
              );
            }

            return SizedBox(
              width: query.size.width,
              height: query.size.height,
              child: ColoredBox(
                color: Theme.of(context).scaffoldBackgroundColor,
              ),
            );
          },
        ),
        children: [
          BlocBuilder<ConversationBloc, ConversationState>(
            buildWhen: (prev, next) =>
                prev.conversation?.showAddToRoster !=
                next.conversation?.showAddToRoster,
            builder: (context, state) {
              final showAddToRoster =
                  state.conversation?.showAddToRoster ?? false;
              if (!showAddToRoster ||
                  state.conversation?.type != ConversationType.chat) {
                return const SizedBox();
              }

              return _renderNotInRosterWidget(state, context);
            },
          ),
          Expanded(
            child: Stack(
              children: [
                StreamBuilder<List<Message>>(
                  initialData: const [],
                  stream: _conversationController.dataStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      return SingleChildScrollView(
                        reverse: true,
                        controller: _conversationController.scrollController,
                        child: GroupedListView<Message, DateTime>(
                          elements: snapshot.data!,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          groupBy: (message) {
                            final dt = DateTime.fromMillisecondsSinceEpoch(
                              message.timestamp,
                            );
                            return DateTime(
                              dt.year,
                              dt.month,
                              dt.day,
                            );
                          },
                          groupSeparatorBuilder: (DateTime dt) => Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              DateBubble(
                                formatDateBubble(dt, DateTime.now()),
                              ),
                            ],
                          ),
                          indexedItemBuilder: (context, message, index) =>
                              _renderBubble(
                            context.read<ConversationBloc>().state,
                            message,
                            snapshot.data!,
                            index,
                            maxWidth,
                          ),
                          sort: false,
                        ),
                      );
                    }

                    return const LinearProgressIndicator();
                  },
                ),
                Positioned(
                  right: 8,
                  bottom: 16,
                  child: Material(
                    color: const Color.fromRGBO(0, 0, 0, 0),
                    child: ScaleTransition(
                      scale: _scrollToBottomAnimation,
                      alignment: FractionalOffset.center,
                      child: SizedBox(
                        width: 45,
                        height: 45,
                        child: FloatingActionButton(
                          heroTag: 'fabScrollDown',
                          backgroundColor:
                              Theme.of(context).scaffoldBackgroundColor,
                          onPressed: _conversationController.animateToBottom,
                          child: const Icon(
                            Icons.arrow_downward,
                            // TODO(Unknown): Theme dependent
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          BlocBuilder<ConversationBloc, ConversationState>(
            buildWhen: (prev, next) =>
                prev.conversation?.chatState != next.conversation?.chatState,
            builder: (context, state) {
              final chatState = state.conversation?.chatState ?? ChatState.gone;
              return AnimatedTypingIndicator(
                visible: chatState == ChatState.composing,
              );
            },
          ),
          BlocBuilder<ConversationBloc, ConversationState>(
            buildWhen: (prev, next) =>
                prev.conversation?.encrypted != next.conversation?.encrypted,
            builder: (context, state) => MobileMessagingTextField(
              keyboardController: _keyboardController,
              conversationController: _conversationController,
              tabController: _tabController,
              speedDialValueNotifier: _speedDialValueNotifier,
              textFieldFocusNode: _textfieldFocusNode,
              isEncrypted: state.conversation?.encrypted ?? false,
              insertionCallback: (content) async {
                assert(
                  content.hasData,
                  'Inserted content has no data',
                );

                // Write the data to a tempoary file
                final extension = extensionFromMime(content.mimeType);
                final fileId = const Uuid().v4();
                final filename = '$fileId.$extension';
                final tempFile = path.join(
                  await MoxxyPlatformApi().getCacheDataPath(),
                  filename,
                );
                await File(tempFile).writeAsBytes(content.data!);

                // Open the SendFiles page
                GetIt.I.get<SendFilesBloc>().add(
                      SendFilesPageRequestedEvent(
                        [
                          SendFilesRecipient(
                            state.conversation!.jid,
                            state.conversation!.titleWithOptionalContact,
                            state.conversation!.avatarPath,
                            state.conversation!.avatarHash,
                            state.conversation!.contactId != null,
                          ),
                        ],
                        SendFilesType.media,
                        paths: [tempFile],
                      ),
                    );
              },
            ),
          ),
        ],
      ),
    );
  }
}
