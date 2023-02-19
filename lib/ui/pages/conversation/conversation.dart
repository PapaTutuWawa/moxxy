import 'dart:async';
import 'dart:io';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:get_it/get_it.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/error_types.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/shared/warning_types.dart';
import 'package:moxxyv2/ui/bloc/conversation_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/controller/conversation_controller.dart';
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/ui/pages/conversation/blink.dart';
import 'package:moxxyv2/ui/pages/conversation/bottom.dart';
import 'package:moxxyv2/ui/pages/conversation/helpers.dart';
import 'package:moxxyv2/ui/pages/conversation/topbar.dart';
import 'package:moxxyv2/ui/service/data.dart';
import 'package:moxxyv2/ui/theme.dart';
import 'package:moxxyv2/ui/widgets/chat/bubbles/date.dart';
import 'package:moxxyv2/ui/widgets/chat/bubbles/new_device.dart';
import 'package:moxxyv2/ui/widgets/chat/chatbubble.dart';
import 'package:moxxyv2/ui/widgets/overview_menu.dart';

class ConversationPage extends StatefulWidget {
  const ConversationPage({
    required this.conversationJid,
    super.key,
  });

  /// The JID of the current conversation
  final String conversationJid;
  
  @override
  ConversationPageState createState() => ConversationPageState();
}

class ConversationPageState extends State<ConversationPage> with TickerProviderStateMixin {
  late final AnimationController _animationController; 
  late final AnimationController _overviewAnimationController;
  late final TabController _tabController;
  late Animation<double> _overviewMsgAnimation;
  late final Animation<double> _scrollToBottom;
  bool _scrolledToBottomState = true;
  late FocusNode _textfieldFocus;
  final ValueNotifier<bool> _isSpeedDialOpen = ValueNotifier(false);

  late final BidirectionalConversationController _conversationController;

  late final StreamSubscription _scrolledToBottomButtonSubscription;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2,
      vsync: this,
    );
    _textfieldFocus = FocusNode();

    _conversationController = BidirectionalConversationController(
      widget.conversationJid,
    );
    _conversationController.fetchOlderMessages();
    _scrolledToBottomButtonSubscription = _conversationController.scrollToBottomStateStream.listen(_onScrollToBottomStateChanged);

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
    _tabController.dispose();
    _conversationController.dispose();
    _animationController.dispose();
    _overviewAnimationController.dispose();
    _textfieldFocus.dispose();
    super.dispose();
  }

  void _onScrollToBottomStateChanged(bool visible) {
    if (visible) {
      _animationController.forward();
    } else {
      _animationController.reverse();
    }
  }
  
  Future<void> _retractMessage(BuildContext context, String originId) async {
    final result = await showConfirmationDialog(
      t.pages.conversation.retract,
      t.pages.conversation.retractBody,
      context,
    );

    if (result) {
      _conversationController.retractMessage(originId);

      // ignore: use_build_context_synchronously
      Navigator.of(context).pop();
    }
  }

  Widget _renderBubble(ConversationState state, Message message, int index, double maxWidth) {
    final item = message;

    if (item.isPseudoMessage) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: maxWidth,
            ),
            child: NewDeviceBubble(
              data: item.pseudoMessageData!,
              title: state.conversation!.title,
            ),
          ),
        ],
      );
    }

    final start = index - 1 < 0 ?
      true :
      false;
//      isSent(state.messages[index - 1], state.jid) != isSent(item, state.jid);
    // final end = index + 1 >= state.messages.length ?
    //   true :
    //   false;
    final end = true;
//      isSent(state.messages[index + 1], state.jid) != isSent(item, state.jid);
    final between = !start && !end;
    final sentBySelf = isSent(message, GetIt.I.get<UIDataService>().ownJid!);
    
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
      onSwipedCallback: _conversationController.quoteMessage,
      onReactionTap: (reaction) {
        if (reaction.reactedBySelf) {
          _conversationController.removeReaction(
            index,
            reaction.emoji,
          );
        } else {
          _conversationController.addReaction(
            index,
            reaction.emoji,
          );
        }
      },
      onLongPressed: (event) async {
        if (!message.isLongpressable) {
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
              if (item.isReactable)
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
                          //height: pickerHeight,
                          config: Config(
                            bgColor: Theme.of(context).scaffoldBackgroundColor,
                          ),
                        ),
                      ),
                    );
                    if (emoji != null) {
                      _conversationController.addReaction(
                        index,
                        emoji,
                      );
                    }

                    // ignore: use_build_context_synchronously
                    Navigator.of(context).pop();
                  },
                ),
              if (item.canRetract(sentBySelf))
                OverviewMenuItem(
                  icon: Icons.delete,
                  text: t.pages.conversation.retract,
                  onPressed: () => _retractMessage(context, item.originId!),
                ),
              // TODO(Unknown): Also allow correcting older messages
              if (item.canEdit(sentBySelf) && state.conversation!.lastMessage?.id == item.id)
                OverviewMenuItem(
                  icon: Icons.edit,
                  text: t.pages.conversation.edit,
                  onPressed: () {
                    _conversationController.beginMessageEditing(
                      item.body,
                      item.quotes,
                      item.id,
                      item.sid,
                    );
                    Navigator.of(context).pop();
                  },
                ),
              if (item.errorMenuVisible)
                OverviewMenuItem(
                  icon: Icons.info_outline,
                  text: t.pages.conversation.showError,
                  onPressed: () {
                    showInfoDialog(
                      t.errors.conversation.messageErrorDialogTitle,
                      errorToTranslatableString(item.errorType!),
                      context,
                    );
                  },
                ),
              if (item.hasWarning)
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
              if (item.isCopyable)
                OverviewMenuItem(
                  icon: Icons.content_copy,
                  text: t.pages.conversation.copy,
                  onPressed: () {
                    // TODO(Unknown): Show a toast saying the message has been copied
                    Clipboard.setData(ClipboardData(text: item.body));
                    Navigator.of(context).pop();
                  },
                ),

              if (item.isQuotable)
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

              if (item.isQuotable)
                OverviewMenuItem(
                  icon: Icons.reply,
                  text: t.pages.conversation.quote,
                  onPressed: () {
                    _conversationController.quoteMessage(item);
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
                child: Text(
                  t.pages.conversation.addToContacts,
                  style: TextStyle(
                    color: Theme
                      .of(context)
                      .extension<MoxxyThemeData>()!
                      .conversationTextFieldColor,
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
                    color: Theme
                      .of(context)
                      .extension<MoxxyThemeData>()!
                      .conversationTextFieldColor,
                  ),
                ),
                onPressed: () => blockJid(state.conversation!.jid, context),
              ),
            )
          ],
        ),
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.6;
    return WillPopScope(
      onWillPop: () async {
        // TODO(PapaTutuWawa): Check if we are recording an audio message and handle
        //                     that accordingly
        final bloc = GetIt.I.get<ConversationBloc>();
        if (!_conversationController.handlePop()) {
          return false;
        }

        if (bloc.state.isRecording) {
          // TODO(PapaTutuWawa): Show a dialog
          return true;
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
                      if (state.conversation?.inRoster == true) return Container();

                      return _renderNotInRosterWidget(state, context);
                    },
                  ),

                  Expanded(
                    child: StreamBuilder<List<Message>>(
                      initialData: [],
                      stream: _conversationController.messageStream,
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
                                final dt = DateTime.fromMillisecondsSinceEpoch(message.timestamp);
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
                              indexedItemBuilder: (context, message, index) => _renderBubble(
                                context.read<ConversationBloc>().state,
                                message,
                                index,
                                maxWidth,
                              ),
                              sort: false,
                            ),
                          );
                        }

                        return CircularProgressIndicator();
                      },
                    ),
                  ),

                  ColoredBox(
                    color: Theme.of(context)
                      .scaffoldBackgroundColor
                      .withOpacity(0.4),
                    child: ConversationBottomRow(
                      _tabController,
                      _textfieldFocus,
                      _conversationController,
                      _isSpeedDialOpen,
                    ),
                  ),
                ],
              ),
            ),
          ),

          StreamBuilder<bool>(
            initialData: false,
            stream: _conversationController.pickerVisibleStream,
            builder: (context, snapshot) => Positioned(
              right: 8,
              bottom: snapshot.data! ?
                pickerHeight + 80 :
                80,
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
                        _conversationController.animateToBottom();
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
          ),

          // Indicator for the swipe to lock gesture
          Positioned(
            right: 53,
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
            right: 61,
            bottom: pickerHeight,
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
                            Theme
                              .of(context)
                              .extension<MoxxyThemeData>()!
                              .conversationTextFieldColor,
                          child: state.isLocked ?
                            BlinkingIcon(
                              icon: Icons.mic,
                              duration: const Duration(milliseconds: 600),
                              start: Colors.white,
                              end: Colors.red.shade600,
                            ) :
                            Icon(
                              Icons.lock,
                              color: Theme
                                .of(context)
                                .extension<MoxxyThemeData>()!
                                .conversationTextFieldTextColor,
                            ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          Positioned(
            right: 61,
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
                          backgroundColor: Theme
                              .of(context)
                              .extension<MoxxyThemeData>()!
                              .conversationTextFieldColor,
                          child: Icon(
                            Icons.delete,
                            color: Theme
                              .of(context)
                              .extension<MoxxyThemeData>()!
                              .conversationTextFieldTextColor,
                          ),
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
