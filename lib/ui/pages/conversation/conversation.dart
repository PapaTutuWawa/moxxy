import 'dart:io';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/error_types.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/shared/warning_types.dart';
import 'package:moxxyv2/ui/bloc/conversation_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/ui/pages/conversation/blink.dart';
import 'package:moxxyv2/ui/pages/conversation/bottom.dart';
import 'package:moxxyv2/ui/pages/conversation/helpers.dart';
import 'package:moxxyv2/ui/pages/conversation/topbar.dart';
import 'package:moxxyv2/ui/widgets/chat/chatbubble.dart';
import 'package:moxxyv2/ui/widgets/overview_menu.dart';

class ConversationPage extends StatefulWidget {
  const ConversationPage({ super.key });

  static MaterialPageRoute<dynamic> get route => MaterialPageRoute<dynamic>(
    builder: (context) => const ConversationPage(),
    settings: const RouteSettings(
      name: conversationRoute,
    ),
  );
  
  @override
  ConversationPageState createState() => ConversationPageState();
}

class ConversationPageState extends State<ConversationPage> with TickerProviderStateMixin {
  ConversationPageState() :
    _controller = TextEditingController(),
    _scrollController = ScrollController(),
    _scrolledToBottomState = true,
    super();
  final TextEditingController _controller;
  final ScrollController _scrollController;
  late final AnimationController _animationController; 
  late final AnimationController _overviewAnimationController;
  late Animation<double> _overviewMsgAnimation;
  late final Animation<double> _scrollToBottom;
  bool _scrolledToBottomState;
  late FocusNode _textfieldFocus;

  @override
  void initState() {
    super.initState();
    _textfieldFocus = FocusNode();
    _scrollController.addListener(_onScroll);

    _overviewAnimationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    // Values taken from here: https://stackoverflow.com/questions/45539395/flutter-float-action-button-hiding-the-visibility-of-items#45598028
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 180),
      vsync: this,
    );
    _scrollToBottom = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.5, 1),
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    _animationController.dispose();
    _overviewAnimationController.dispose();
    _textfieldFocus.dispose();
    super.dispose();
  }

  void _quoteMessage(BuildContext context, Message message) {
    context.read<ConversationBloc>().add(MessageQuotedEvent(message));
  }

  Future<void> _retractMessage(BuildContext context, String originId) async {
    final result = await showConfirmationDialog(
      t.pages.conversation.retract,
      t.pages.conversation.retractBody,
      context,
    );

    if (result) {
      // ignore: use_build_context_synchronously
      context.read<ConversationBloc>().add(
        MessageRetractedEvent(originId),
      );

      // ignore: use_build_context_synchronously
      Navigator.of(context).pop();
    }
  }
  
  Widget _renderBubble(ConversationState state, BuildContext context, int _index, double maxWidth, String jid) {
    // TODO(Unknown): Since we reverse the list: Fix start, end and between
    final index = state.messages.length - 1 - _index;
    final item = state.messages[index];
    final start = index - 1 < 0 ?
      true :
      isSent(state.messages[index - 1], jid) != isSent(item, jid);
    final end = index + 1 >= state.messages.length ?
      true :
      isSent(state.messages[index + 1], jid) != isSent(item, jid);
    final between = !start && !end;
    final lastMessageTimestamp = index > 0 ? state.messages[index - 1].timestamp : null;
    final sentBySelf = isSent(item, jid);
    
    final bubble = RawChatBubble(
      item,
      maxWidth,
      sentBySelf,
      state.conversation!.encrypted,
      start,
      between,
      end,
    );
    
    return ChatBubble(
      bubble: bubble,
      message: item,
      sentBySelf: sentBySelf,
      maxWidth: maxWidth,
      lastMessageTimestamp: lastMessageTimestamp,
      onSwipedCallback: (_) => _quoteMessage(context, item),
      onReactionTap: (reaction) {
        final bloc = context.read<ConversationBloc>();
        if (reaction.reactedBySelf) {
          bloc.add(
            ReactionRemovedEvent(
              reaction.emoji,
              index,
            ),
          );
        } else {
          bloc.add(
            ReactionAddedEvent(
              reaction.emoji,
              index,
            ),
          );
        }
      },
      onLongPressed: (event) async {
        if (!item.isLongpressable) {
          return;
        }

        Vibrate.feedback(FeedbackType.medium);

        _overviewMsgAnimation = Tween<double>(
          begin: event.globalPosition.dy - 20,
          end: 200,
        ).animate(
          CurvedAnimation(
            parent: _overviewAnimationController,
            curve: Curves.easeInOutCubic,
          ),
        );
        // TODO(PapaTutuWawa): Animate the message to the center?
        //_msgX = Tween<double>(
        //  begin: 8,
        //  end: (MediaQuery.of(context).size.width - obj.paintBounds.width) / 2,
        //).animate(_controller);

        await _overviewAnimationController.forward();
        await showDialog<void>(
          context: context,
          builder: (context) => OverviewMenu(
            _overviewMsgAnimation,
            rightBorder: sentBySelf,
            left: sentBySelf ? null : 8,
            right: sentBySelf ? 8 : null,
            highlightMaterialBorder: RawChatBubble.getBorderRadius(
              sentBySelf,
              start,
              between,
              end,
            ),
            highlight: bubble,
            materialColor: item.isSticker ?
              Colors.transparent :
              null,
            children: [
              ...item.isReactable ? [
                OverviewMenuItem(
                  icon: Icons.add_reaction,
                  text: t.pages.conversation.addReaction,
                  onPressed: () async {
                    final emoji = await showModalBottomSheet<String>(
                      context: context,
                      // TODO(PapaTutuWawa): Move this to the theme
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.only(
                          topLeft: radiusLarge,
                          topRight: radiusLarge,
                        ),
                      ),
                      builder: (context) => Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: EmojiPicker(
                          onEmojiSelected: (_, emoji) {
                            // ignore: use_build_context_synchronously
                            Navigator.of(context).pop(emoji.emoji);
                          },
                          //height: 250,
                          config: Config(
                            bgColor: Theme.of(context).scaffoldBackgroundColor,
                          ),
                        ),
                      ),
                    );
                    if (emoji != null) {
                      // ignore: use_build_context_synchronously
                      context.read<ConversationBloc>().add(
                        ReactionAddedEvent(emoji, index),
                      );
                    }

                    // ignore: use_build_context_synchronously
                    Navigator.of(context).pop();
                  },
                ),
              ] : [],
              ...item.canRetract(sentBySelf) ? [
                OverviewMenuItem(
                  icon: Icons.delete,
                  text: t.pages.conversation.retract,
                  onPressed: () => _retractMessage(context, item.originId!),
                ),
              ] : [],
              // TODO(Unknown): Also allow correcting older messages
              ...item.canEdit(sentBySelf) && state.conversation!.lastMessage?.id == item.id ? [
                OverviewMenuItem(
                  icon: Icons.edit,
                  text: t.pages.conversation.edit,
                  onPressed: () {
                    context.read<ConversationBloc>().add(
                      MessageEditSelectedEvent(item),
                    );
                    _controller.text = item.body;
                    Navigator.of(context).pop();
                  },
                ),
              ] : [],
              ...item.errorMenuVisible ? [
                OverviewMenuItem(
                  icon: Icons.info_outline,
                  text: t.pages.conversation.showError,
                  onPressed: () {
                    showInfoDialog(
                      'Error',
                      errorToTranslatableString(item.errorType!),
                      context,
                    );
                  },
                ),
              ] : [],
              ...item.hasWarning ? [
                OverviewMenuItem(
                  icon: Icons.warning,
                  text: t.pages.conversation.showWarning,
                  onPressed: () {
                    showInfoDialog(
                      'Warning',
                      warningToTranslatableString(item.warningType!),
                      context,
                    );
                  },
                ),
              ] : [],
              ...item.isCopyable ? [
                OverviewMenuItem(
                  icon: Icons.content_copy,
                  text: t.pages.conversation.copy,
                  onPressed: () {
                    // TODO(Unknown): Show a toast saying the message has been copied
                    Clipboard.setData(ClipboardData(text: item.body));
                    Navigator.of(context).pop();
                  },
                ),
              ] : [],
              ...item.isQuotable ? [
                OverviewMenuItem(
                  icon: Icons.forward,
                  text: t.pages.conversation.forward,
                  onPressed: () {
                    showNotImplementedDialog(
                      'sharing',
                      context,
                    );
                  },
                ),
              ] : [],
              OverviewMenuItem(
                icon: Icons.reply,
                text: t.pages.conversation.quote,
                onPressed: () {
                  _quoteMessage(context, item);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );

        await _overviewAnimationController.reverse();
      },
    );
  }
  
  /// Render a widget that allows the user to either block the user or add them to their
  /// roster
  Widget _renderNotInRosterWidget(ConversationState state, BuildContext context) {
    return ColoredBox(
      color: Colors.black38,
      child: SizedBox(
        height: 64,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: TextButton(
                child: Text(t.pages.conversation.addToContacts),
                onPressed: () async {
                  final jid = state.conversation!.jid;
                  final result = await showConfirmationDialog(
                    t.pages.conversation.addToContactsTitle(jid: jid),
                    t.pages.conversation.addToContactsBody(jid: jid),
                    context,
                  );

                  if (result) {
                    // TODO(Unknown): Maybe show a progress indicator
                    // TODO(Unknown): Have the page update its state once the addition is done
                    // ignore: use_build_context_synchronously
                    context.read<ConversationBloc>().add(
                      JidAddedEvent(jid),
                    );

                    // ignore: use_build_context_synchronously
                    Navigator.of(context).pop();
                  }
                },
              ),
            ),
            Expanded(
              child: TextButton(
                child: Text(t.pages.conversation.blockShort),
                onPressed: () => blockJid(state.conversation!.jid, context),
              ),
            )
          ],
        ),
      ),
    );
  }

  /// Taken from https://bloclibrary.dev/#/flutterinfinitelisttutorial
  bool _isScrolledToBottom() {
    if (!_scrollController.hasClients) return false;

    return _scrollController.offset <= 10;
  }
  
  void _onScroll() {
    final isScrolledToBottom = _isScrolledToBottom();
    if (isScrolledToBottom && !_scrolledToBottomState) {
      _animationController.reverse();
    } else if (!isScrolledToBottom && _scrolledToBottomState) {
      _animationController.forward();
    }

    _scrolledToBottomState = isScrolledToBottom;
  }
  
  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.6;
    
    return WillPopScope(
      onWillPop: () async {
        // TODO(PapaTutuWawa): Check if we are recording an audio message and handle
        //                     that accordingly
        final bloc = GetIt.I.get<ConversationBloc>();
        if (bloc.state.isRecording) {
          // TODO(PapaTutuWawa): Show a dialog
          return true;
        } else if (bloc.state.emojiPickerVisible) {
          bloc.add(EmojiPickerToggledEvent(handleKeyboard: false));

          return false;
        } else if (bloc.state.stickerPickerVisible) {
          bloc.add(StickerPickerToggledEvent());
          if (_textfieldFocus.hasFocus) {
            _textfieldFocus.unfocus();
          }

          return false;
        } else {
          bloc.add(CurrentConversationResetEvent());

          return true;
        }
      },
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 0,
            child: ColoredBox(color: Theme.of(context).scaffoldBackgroundColor),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: BlocBuilder<ConversationBloc, ConversationState>(
              buildWhen: (prev, next) => prev.backgroundPath != next.backgroundPath,
              builder: (context, state) {
                final query = MediaQuery.of(context);

                if (state.backgroundPath.isNotEmpty) {
                  return Image.file(
                    File(state.backgroundPath),
                    fit: BoxFit.cover,
                    width: query.size.width,
                    height: query.size.height - query.padding.top,
                  );
                }

                return SizedBox(
                  width: query.size.width,
                  height: query.size.height,
                  child: ColoredBox(color: Theme.of(context).scaffoldBackgroundColor),
                );
              },
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 0,
            child: Scaffold(
              // TODO(Unknown): Maybe replace the scaffold itself to prevent transparency
              backgroundColor: const Color.fromRGBO(0, 0, 0, 0),
              appBar: const ConversationTopbar(),
              body: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  BlocBuilder<ConversationBloc, ConversationState>(
                    buildWhen: (prev, next) => prev.conversation?.inRoster != next.conversation?.inRoster,
                    builder: (context, state) {
                      if (state.conversation!.inRoster) return Container();

                      return _renderNotInRosterWidget(state, context);
                    },
                  ),

                  BlocBuilder<ConversationBloc, ConversationState>(
                    // NOTE: We don't need to update when the jid changes as it should
                    //       be static over the entire lifetime of the BLoC.
                    buildWhen: (prev, next) => prev.messages != next.messages || prev.conversation!.encrypted != next.conversation!.encrypted,
                    builder: (context, state) => Expanded(
                      child: ListView.builder(
                        reverse: true,
                        itemCount: state.messages.length,
                        itemBuilder: (context, index) => _renderBubble(
                          state,
                          context,
                          index,
                          maxWidth,
                          state.jid,
                        ),
                        shrinkWrap: true,
                        controller: _scrollController,
                      ),
                    ),
                  ),

                  ConversationBottomRow(
                    _controller,
                    _textfieldFocus,
                  ),
                ],
              ),
            ),
          ),

          Positioned(
            right: 8,
            bottom: 80,
            child: Material(
              color: const Color.fromRGBO(0, 0, 0, 0),
              child: ScaleTransition(
                scale: _scrollToBottom,
                alignment: FractionalOffset.center,
                child: SizedBox(
                  width: 45,
                  height: 45,
                  child: FloatingActionButton(
                    heroTag: 'fabScrollDown',
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    onPressed: () {
                      _scrollController.jumpTo(0);
                    },
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

          // Indicator for the swipe to lock gesture
          Positioned(
            right: 8,
            bottom: 100,
            child: IgnorePointer(
              child: BlocBuilder<ConversationBloc, ConversationState>(
                builder: (context, state) {
                  return AnimatedScale(
                    scale: state.isRecording && !state.isLocked ? 1 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: SizedBox(
                      height: 24 * 3,
                      width: 47,
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: const [
                          Positioned(
                            bottom: 0,
                            child: Icon(
                              Icons.keyboard_arrow_up,
                              size: 48,
                            ),
                          ),
                          Positioned(
                            bottom: 12,
                            child: Icon(
                              Icons.keyboard_arrow_up,
                              size: 48,
                            ),
                          ),
                          Positioned(
                            bottom: 24,
                            child: Icon(
                              Icons.keyboard_arrow_up,
                              size: 48,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          Positioned(
            right: 8,
            bottom: 250,
            child: BlocBuilder<ConversationBloc, ConversationState>(
              builder: (context, state) {
                return DragTarget<int>(
                  onWillAccept: (data) => state.isDragging,
                  onAccept: (_) {
                    context.read<ConversationBloc>().add(
                      SendButtonLockedEvent(),
                    );
                  },
                  builder: (context, _, __) {
                    return AnimatedScale(
                      scale: state.isDragging || state.isLocked ? 1 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: SizedBox(
                        height: 45,
                        width: 45,
                        child: FloatingActionButton(
                          heroTag: 'fabLock',
                          onPressed: state.isLocked ?
                          () {
                            context.read<ConversationBloc>().add(
                              SendButtonLockPressedEvent(),
                            );
                          } :
                          null,
                          backgroundColor: state.isLocked ?
                            Colors.red.shade600 :
                            Colors.grey,
                          child: state.isLocked ?
                            BlinkingIcon(
                              icon: Icons.mic,
                              duration: const Duration(milliseconds: 600),
                              start: Colors.white,
                              end: Colors.red.shade600,
                            ) :
                            const Icon(Icons.lock, color: Colors.white),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          Positioned(
            right: 8,
            bottom: 380,
            child: BlocBuilder<ConversationBloc, ConversationState>(
              builder: (context, state) {
                return DragTarget<int>(
                  onWillAccept: (_) => state.isDragging,
                  onAccept: (_) {
                    context.read<ConversationBloc>().add(
                      RecordingCanceledEvent(),
                    );
                  },
                  builder: (context, _, __) {
                    return AnimatedScale(
                      scale: state.isDragging || state.isLocked ? 1 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: SizedBox(
                        height: 45,
                        width: 45,
                        child: FloatingActionButton(
                          heroTag: 'fabCancel',
                          onPressed: state.isLocked ?
                          () {
                            context.read<ConversationBloc>().add(
                              RecordingCanceledEvent(),
                            );
                          } :
                          null,
                          backgroundColor: Colors.grey,
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
