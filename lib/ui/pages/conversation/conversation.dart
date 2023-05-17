import 'dart:ui';
import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:get_it/get_it.dart';
import 'package:grouped_list/grouped_list.dart';
import 'package:moxplatform/moxplatform.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/error_types.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/shared/models/conversation.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/shared/warning_types.dart';
import 'package:moxxyv2/ui/bloc/conversation_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/controller/conversation_controller.dart';
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/ui/pages/conversation/blink.dart';
import 'package:moxxyv2/ui/pages/conversation/bottom.dart';
import 'package:moxxyv2/ui/pages/conversation/helpers.dart';
import 'package:moxxyv2/ui/pages/conversation/keyboard_dodging.dart';
import 'package:moxxyv2/ui/pages/conversation/topbar.dart';
import 'package:moxxyv2/ui/service/data.dart';
import 'package:moxxyv2/ui/theme.dart';
import 'package:moxxyv2/ui/widgets/chat/bubbles/date.dart';
import 'package:moxxyv2/ui/widgets/chat/bubbles/new_device.dart';
import 'package:moxxyv2/ui/widgets/chat/chatbubble.dart';
import 'package:moxxyv2/ui/widgets/chat/message.dart';
import 'package:moxxyv2/ui/widgets/overview_menu.dart';
import 'package:moxxyv2/ui/widgets/textfield.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class _TextFieldIconButton extends StatelessWidget {
  const _TextFieldIconButton(this.icon, this.onTap);
  final void Function() onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Icon(
          icon,
          size: 24,
          color: primaryColor,
        ),
      ),
    );
  }
}

/// A wrapper widget to easily obscure a widget with a skim when the highlight
/// animation is playing.
class HighlightHackWrapper extends StatelessWidget {
  const HighlightHackWrapper({
    required this.controller,
    required this.animation,
    required this.child,
  });

  /// The controller controlling the fade animation.
  final AnimationController controller;

  /// The fade animation.
  final Animation<double> animation;

  /// The child to show below.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, c) => Stack(
        children: [
          c!,
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            bottom: 0,
            child: IgnorePointer(
              ignoring: animation.value == 0,
              child: GestureDetector(
                onTap: () => controller.reverse(),
                child: ColoredBox(
                  color: animation.value != 0
                      ? highlightSkimColor.withOpacity(
                          animation.value,
                        )
                      : Colors.transparent,
                ),
              ),
            ),
          ),
        ],
      ),
      child: child,
    );
  }
}

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

class ConversationPageState extends State<ConversationPage>
    with TickerProviderStateMixin {
  /// Controllers for the bottom input field
  late final BidirectionalConversationController _conversationController;
  late final StreamSubscription<bool> _scrolledToBottomButtonSubscription;
  late final TabController _tabController;
  final KeyboardReplacerController _keyboardController =
      KeyboardReplacerController();
  final FocusNode _textfieldFocusNode = FocusNode();
  final ValueNotifier<bool> _speedDialValueNotifier = ValueNotifier(false);

  /// Controllers, animation, and state for the selection animation
  late final AnimationController _selectionAnimationController;
  late final Tween<double> _selectionTween;
  late final Animation<double> _selectionAnimation;
  double _messageYBottom = 0;
  double _messageYTop = 0;
  double? _overviewLeft;
  double? _overviewRight;
  Message? _selectedMessage;
  bool _sentBySelf = false;

  /// Controllers and state for the "scroll to bottom" animation
  late final AnimationController _scrollToBottomAnimationController;
  late final Animation<double> _scrollToBottomAnimation;
  late final StreamSubscription<bool> _scrolledToBottomStateSubscription;

  @override
  void initState() {
    super.initState();

    // Setup message paging
    _conversationController = BidirectionalConversationController(
      widget.conversationJid,
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
    _selectionTween = Tween<double>(
      begin: 0,
      end: 0.6,
    );
    _selectionAnimation = _selectionTween.animate(
      CurvedAnimation(
        parent: _selectionAnimationController,
        curve: Curves.easeInOutCubic,
      ),
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
            )
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
            child: NewDeviceBubble(
              data: item.pseudoMessageData!,
              title: state.conversation!.title,
            ),
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

    final bubble = RawChatBubble(
      item,
      maxWidth,
      sentBySelf,
      state.conversation!.encrypted,
      start,
      between,
      end,
    );

    final key = GlobalKey();
    return AnimatedBuilder(
      animation: _selectionAnimation,
      child: ChatBubble(
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

          final ro = key.currentContext!.findRenderObject()!;
          final trans = ro.getTransformTo(null).getTranslation();
          final off = Offset(trans.x, trans.y);
          final r = ro.paintBounds.shift(off);
          _messageYBottom = r.bottom - 90;
          _messageYTop = r.top;

          _selectedMessage = item;
          _sentBySelf = sentBySelf;

          _overviewLeft = sentBySelf ? 20 : null;
          _overviewRight = sentBySelf ? null : 20;

          _selectionAnimationController.forward();
        },
        key: key,
      ),
      builder: (context, child) => ColoredBox(
        color: _selectionAnimation.value != 0 && _selectedMessage?.id == item.id
            ? highlightSkimColor.withOpacity(
                _selectionAnimation.value,
              )
            : Colors.transparent,
        child: GestureDetector(
          onTap: _selectionAnimation.value != 0
              ? () => _selectionAnimationController.reverse()
              : null,
          child: child,
        ),
      ),
    );
  }

  Future<void> _retractMessage(BuildContext context, String originId) async {
    final result = await showConfirmationDialog(
      t.pages.conversation.retract,
      t.pages.conversation.retractBody,
      context,
    );

    if (result) {
      _conversationController.retractMessage(originId);
    }
  }

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.6;
    return KeyboardReplacerScaffold(
      controller: _keyboardController,
      // TODO
      keyboardWidget: const ColoredBox(color: Colors.pink),
      appbar: HighlightHackWrapper(
        animation: _selectionAnimation,
        controller: _selectionAnimationController,
        child: const ConversationTopbar(),
      ),
      background: BlocBuilder<ConversationBloc, ConversationState>(
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
            child: ColoredBox(
              color: Theme.of(context).scaffoldBackgroundColor,
            ),
          );
        },
      ),
      children: [
        BlocBuilder<ConversationBloc, ConversationState>(
          buildWhen: (prev, next) =>
              prev.conversation?.inRoster != next.conversation?.inRoster,
          builder: (context, state) {
            if ((state.conversation?.inRoster ?? false) ||
                state.conversation?.type == ConversationType.note) {
              return SizedBox();
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
              AnimatedBuilder(
                animation: _selectionAnimation,
                builder: (context, _) => Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: IgnorePointer(
                    ignoring: _selectionAnimation.value == 0,
                    child: GestureDetector(
                      onTap: () {
                        _selectionAnimationController.reverse();
                      },
                      child: SizedBox(
                        height: _messageYTop == 0 ? 0 : _messageYTop - 60 - 30,
                        child: ColoredBox(
                          color: highlightSkimColor.withOpacity(
                            _selectionAnimation.value,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: _selectionAnimation,
                builder: (context, _) => Positioned(
                  top: _messageYBottom,
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: IgnorePointer(
                    ignoring: _selectionAnimation.value == 0,
                    child: GestureDetector(
                      onTap: () {
                        _selectionAnimationController.reverse();
                      },
                      child: ColoredBox(
                        color: highlightSkimColor.withOpacity(
                          _selectionAnimation.value,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: _selectionAnimation,
                builder: (context, _) => Positioned(
                  left: _overviewLeft,
                  right: _overviewRight,
                  bottom: 20,
                  child: IgnorePointer(
                    ignoring: _selectionAnimation.value == 0,
                    child: Opacity(
                      opacity:
                          (_selectionAnimation.value / _selectionTween.end!),
                      child: OverviewMenu2(
                        children: [
                          if (_selectedMessage?.isReactable ?? false)
                            OverviewMenuItem(
                              icon: Icons.add_reaction,
                              text: t.pages.conversation.addReaction,
                              onPressed: () async {
                                final emoji =
                                    await pickEmoji(context, pop: false);
                                if (emoji != null) {
                                  await MoxplatformPlugin.handler
                                      .getDataSender()
                                      .sendData(
                                        AddReactionToMessageCommand(
                                          messageId: _selectedMessage!.id,
                                          emoji: emoji,
                                          conversationJid:
                                              _conversationController
                                                  .conversationJid,
                                        ),
                                        awaitable: false,
                                      );
                                }

                                _selectionAnimationController.reverse();
                              },
                            ),

                          if (_selectedMessage?.canRetract(_sentBySelf) ??
                              false)
                            OverviewMenuItem(
                              icon: Icons.delete,
                              text: t.pages.conversation.retract,
                              onPressed: () {
                                _retractMessage(
                                    context, _selectedMessage!.originId!);
                                _selectionAnimationController.reverse();
                              },
                            ),

                          // TODO(Unknown): Also allow correcting older messages
                          if ((_selectedMessage?.canEdit(_sentBySelf) ??
                                  false) &&
                              GetIt.I
                                      .get<ConversationBloc>()
                                      .state
                                      .conversation
                                      ?.lastMessage
                                      ?.id ==
                                  _selectedMessage?.id)
                            OverviewMenuItem(
                              icon: Icons.edit,
                              text: t.pages.conversation.edit,
                              onPressed: () {
                                _conversationController.beginMessageEditing(
                                  _selectedMessage!.body,
                                  _selectedMessage!.quotes,
                                  _selectedMessage!.id,
                                  _selectedMessage!.sid,
                                );
                                _selectionAnimationController.reverse();
                              },
                            ),

                          if (_selectedMessage?.errorMenuVisible ?? false)
                            OverviewMenuItem(
                              icon: Icons.info_outline,
                              text: t.pages.conversation.showError,
                              onPressed: () {
                                showInfoDialog(
                                  t.errors.conversation.messageErrorDialogTitle,
                                  errorToTranslatableString(
                                      _selectedMessage!.errorType!),
                                  context,
                                );
                                _selectionAnimationController.reverse();
                              },
                            ),

                          if (_selectedMessage?.hasWarning ?? false)
                            OverviewMenuItem(
                              icon: Icons.warning,
                              text: t.pages.conversation.showWarning,
                              onPressed: () {
                                showInfoDialog(
                                  'Warning',
                                  warningToTranslatableString(
                                      _selectedMessage!.warningType!),
                                  context,
                                );
                                _selectionAnimationController.reverse();
                              },
                            ),

                          if (_selectedMessage?.isCopyable ?? false)
                            OverviewMenuItem(
                              icon: Icons.content_copy,
                              text: t.pages.conversation.copy,
                              onPressed: () {
                                // TODO(Unknown): Show a toast saying the message has been copied
                                Clipboard.setData(ClipboardData(
                                    text: _selectedMessage!.body));
                                _selectionAnimationController.reverse();
                              },
                            ),

                          if ((_selectedMessage?.isQuotable ?? false) &&
                              _selectedMessage?.conversationJid != '')
                            OverviewMenuItem(
                              icon: Icons.forward,
                              text: t.pages.conversation.forward,
                              onPressed: () {
                                showNotImplementedDialog(
                                  'sharing',
                                  context,
                                );
                                _selectionAnimationController.reverse();
                              },
                            ),

                          if (_selectedMessage?.isQuotable ?? false)
                            OverviewMenuItem(
                              icon: Icons.reply,
                              text: t.pages.conversation.quote,
                              onPressed: () {
                                _conversationController
                                    .quoteMessage(_selectedMessage!);
                                _selectionAnimationController.reverse();
                              },
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 8,
                bottom: 16,
                child: StreamBuilder<bool>(
                  initialData: false,
                  stream: _conversationController.pickerVisibleStream,
                  builder: (context, snapshot) => Material(
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
              ),
            ],
          ),
        ),
        HighlightHackWrapper(
          animation: _selectionAnimation,
          controller: _selectionAnimationController,
          child: ConversationInput(
            keyboardController: _keyboardController,
            conversationController: _conversationController,
            tabController: _tabController,
            speedDialValueNotifier: _speedDialValueNotifier,
            // TODO
            isEncrypted: false,
          ),
        ),
      ],
    );
  }
}
