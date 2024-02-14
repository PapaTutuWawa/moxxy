import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/models/conversation.dart';
import 'package:moxxyv2/ui/bloc/account.dart';
import 'package:moxxyv2/ui/bloc/conversation_bloc.dart';
import 'package:moxxyv2/ui/bloc/conversations.dart';
import 'package:moxxyv2/ui/bloc/request_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/ui/pages/home/accounts.dart';
import 'package:moxxyv2/ui/pages/home/appbar.dart';
import 'package:moxxyv2/ui/post_build.dart';
import 'package:moxxyv2/ui/request_dialog.dart';
import 'package:moxxyv2/ui/widgets/avatar.dart';
import 'package:moxxyv2/ui/widgets/context_menu.dart';
import 'package:moxxyv2/ui/widgets/conversation_card.dart';

enum ConversationsOptions { settings }

class ConversationsRowDismissible extends StatefulWidget {
  const ConversationsRowDismissible({
    required this.item,
    required this.child,
    super.key,
  });
  final Conversation item;
  final Widget child;

  @override
  ConversationsRowDismissibleState createState() =>
      ConversationsRowDismissibleState();
}

class ConversationsRowDismissibleState
    extends State<ConversationsRowDismissible> {
  DismissDirection direction = DismissDirection.none;

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: ValueKey('conversation;${widget.item}'),
      // TODO(Unknown): Show a snackbar allowing the user to revert the action
      // TODO: Fix
      onDismissed: (direction) {},
      /*context.read<OldConversationsBloc>().add(
            ConversationClosedEvent(widget.item.jid),
          ),*/
      onUpdate: (details) {
        if (details.direction != direction) {
          setState(() {
            direction = details.direction;
          });
        }
      },
      background: ColoredBox(
        color: Colors.red,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Visibility(
                visible: direction == DismissDirection.startToEnd,
                child: const Icon(Icons.delete),
              ),
              const Spacer(),
              Visibility(
                visible: direction == DismissDirection.endToStart,
                child: const Icon(Icons.delete),
              ),
            ],
          ),
        ),
      ),
      child: widget.child,
    );
  }
}

class ConversationsPage extends StatefulWidget {
  const ConversationsPage({super.key});

  static MaterialPageRoute<dynamic> get route => MaterialPageRoute<dynamic>(
        builder: (context) => const ConversationsPage(),
        settings: const RouteSettings(
          name: homeRoute,
        ),
      );

  @override
  ConversationsPageState createState() => ConversationsPageState();
}

class ConversationsPageState extends State<ConversationsPage>
    with TickerProviderStateMixin {
  /// The JID of the currently selected conversation.
  Conversation? _selectedConversation;

  /// Data for the context menu animation
  late final AnimationController _contextMenuController;
  late final Animation<double> _contextMenuAnimation;
  final Map<String, GlobalKey> _conversationKeys = {};

  /// The required offset from the top of the stack for the context menu.
  double? _topStackOffset;
  double? _bottomStackOffset;

  /// The overlay entry of the context menu.
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();

    _contextMenuController = AnimationController(
      duration: const Duration(milliseconds: 250),
      vsync: this,
    );
    _contextMenuAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(
      CurvedAnimation(
        parent: _contextMenuController,
        curve: Curves.easeInOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _contextMenuController.dispose();
    _dismissOverlay();

    super.dispose();
  }

  void _dismissOverlay() {
    _overlayEntry?.remove();
    _overlayEntry?.dispose();
    _overlayEntry = null;
  }

  Future<void> _showContextMenu(BuildContext context) async {
    _dismissOverlay();
    _overlayEntry = OverlayEntry(
      builder: (context) {
        return Stack(
          children: [
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              bottom: 0,
              child: GestureDetector(
                onTap: dismissContextMenu,
                // NOTE: We must set the color to Colors.transparent because the container
                // would otherwise not span the entire screen (or Scaffold body to be
                // more precise).
                child: const ColoredBox(
                  color: Colors.transparent,
                ),
              ),
            ),
            Positioned(
              top: _topStackOffset,
              bottom: _bottomStackOffset,
              right: pxToLp(48),
              child: AnimatedBuilder(
                animation: _contextMenuAnimation,
                builder: (context, child) => IgnorePointer(
                  ignoring: _selectedConversation == null,
                  child: Opacity(
                    opacity: _contextMenuAnimation.value,
                    child: child,
                  ),
                ),
                child: ContextMenu(
                  children: [
                    if ((_selectedConversation?.unreadCounter ?? 0) > 0)
                      ContextMenuItem(
                        icon: Icons.done_all,
                        text: t.pages.conversations.markAsRead,
                        onPressed: () async {
                          await context
                              .read<ConversationsCubit>()
                              .markConversationAsRead(
                                _selectedConversation!.jid,
                              );
                          dismissContextMenu();
                        },
                      ),
                    ContextMenuItem(
                      icon: Icons.close,
                      text: t.pages.conversations.closeChat,
                      onPressed: () async {
                        // ignore: use_build_context_synchronously
                        final result = await showConfirmationDialog(
                          t.pages.conversations.closeChat,
                          t.pages.conversations.closeChatBody(
                            conversationTitle:
                                _selectedConversation?.title ?? '',
                          ),
                          context,
                        );

                        if (result) {
                          // TODO(Unknown): Show a snackbar allowing the user to revert the action
                          // TODO: Fix
                          // ignore: use_build_context_synchronously
                          /*context.read<OldConversationsBloc>().add(
                                  ConversationClosedEvent(
                                    _selectedConversation!.jid,
                                  ),
                                );*/
                          dismissContextMenu();
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
    Overlay.of(context).insert(_overlayEntry!);
    await _contextMenuController.forward();
  }

  void dismissContextMenu() {
    _contextMenuController.reverse();
    setState(() {
      _selectedConversation = null;
    });
    _dismissOverlay();
  }

  Widget _listWrapper(BuildContext context, List<Conversation> state) {
    if (state.isNotEmpty) {
      final highlightWord =
          context.read<ConversationsCubit>().searchBarController.text;
      return ListView.builder(
        itemCount: state.length,
        itemBuilder: (context, index) {
          final item = state[index];

          GlobalKey key;
          if (_conversationKeys.containsKey(item.jid)) {
            key = _conversationKeys[item.jid]!;
          } else {
            key = GlobalKey();
            _conversationKeys[item.jid] = key;
          }

          // TODO: Port the rest
          /*final row = ConversationsListRow(
            item,
            true,
            enableAvatarOnTap: true,
            isSelected: _selectedConversation?.jid == item.jid,
            onPressed: () {
              GetIt.I.get<ConversationBloc>().add(
                    RequestedConversationEvent(
                      item.jid,
                      item.title,
                      item.avatarPath,
                    ),
                  );
            },
            key: key,
          );*/
          final row = ConversationCard(
            conversation: item,
            highlightWord: highlightWord,
            onTap: () {
              // Reset the search first.
              context.read<ConversationsCubit>().closeSearchBar();

              // Then request the conversation.
              GetIt.I.get<ConversationBloc>().add(
                    RequestedConversationEvent(
                      item.jid,
                      item.title,
                      item.avatarPath,
                    ),
                  );
            },
            key: key,
          );

          return ConversationsRowDismissible(
            item: item,
            child: GestureDetector(
              onLongPressStart: (event) async {
                Vibrate.feedback(FeedbackType.medium);

                // TODO: Move this into the ContextMenu class as a static method.
                final widgetRect = getWidgetPositionOnScreen(key);
                final height = MediaQuery.of(context).size.height;

                setState(() {
                  _selectedConversation = item;

                  final numberOptions = item.numberContextMenuOptions;
                  if (height - widgetRect.bottom - pxToLp(96) >
                      ContextMenu.computeHeight(context, numberOptions)) {
                    // We have enough space to fit all items below the conversation.
                    // Note: 96 is half the height of the conversation cards.
                    _topStackOffset = widgetRect.top + pxToLp(96);
                    _bottomStackOffset = null;
                  } else {
                    // We don't have enough space below.
                    _topStackOffset = null;
                    _bottomStackOffset = widgetRect.bottom - pxToLp(96);
                  }
                });

                await _showContextMenu(context);
              },
              child: row,
            ),
          );
        },
      );
    }

    final hasSearchResults =
        context.read<ConversationsCubit>().state.searchResults != null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: paddingVeryLarge),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8),
            // TODO(Unknown): Maybe somehow render the svg
            child: Image.asset(
              hasSearchResults
                  ? 'assets/images/empty.png'
                  : 'assets/images/begin_chat.png',
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              hasSearchResults
                  ?
                  // TODO: i18n
                  'No search results...'
                  : t.pages.conversations.noOpenChats,
            ),
          ),
          if (!hasSearchResults)
            TextButton(
              child: Text(t.pages.conversations.startChat),
              onPressed: () =>
                  Navigator.pushNamed(context, newConversationRoute),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_overlayEntry != null) {
          _dismissOverlay();
          return false;
        }

        final cubit = context.read<ConversationsCubit>();
        if (cubit.state.searchOpen) {
          cubit.closeSearchBar();
          return false;
        }

        return true;
      },
      child: PostBuildWidget(
        postBuild: () async {
          final bloc = GetIt.I.get<RequestBloc>();
          if (bloc.state.shouldShow) {
            await showDialog<void>(
              context: context,
              barrierDismissible: false,
              builder: (_) => const RequestDialog(),
            );
          }
        },
        child: Scaffold(
          appBar: ConversationsHomeAppBar(
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            backgroundColor: Theme.of(context).colorScheme.surface,
            //automaticallyImplyLeading: false,
            //elevation: 0,
            //toolbarHeight: 70,
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // TODO: Fix padding
                Padding(
                  padding: const EdgeInsets.only(right: 14),
                  child: SquircleCachingXMPPAvatar.self(
                    size: pxToLp(104),
                    borderRadius: pxToLp(104),
                    onTap: () {
                      // Compute the max extent.
                      AccountsBottomModal.show(context);
                    },
                  ),
                ),

                BlocBuilder<AccountCubit, AccountState>(
                  builder: (context, account) => Text(
                    account.account.displayName,
                    style: TextStyle(
                      fontSize: ptToFontSize(32),
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.inverseSurface,
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(
                  Icons.settings_outlined,
                  size: pxToLp(72),
                ),
                onPressed: () {
                  Navigator.pushNamed(context, settingsRoute);
                },
              ),
            ],
          ),
          body: Column(
            children: [
              BlocBuilder<ConversationsCubit, ConversationsState>(
                buildWhen: (prev, next) => prev.isSearching != next.isSearching,
                builder: (context, state) {
                  if (!state.isSearching) {
                    return const SizedBox();
                  }

                  return const LinearProgressIndicator();
                },
              ),
              Expanded(
                child: Material(
                  color: Theme.of(context).colorScheme.surface,
                  surfaceTintColor: Theme.of(context).colorScheme.surfaceTint,
                  child: BlocBuilder<ConversationsCubit, ConversationsState>(
                    buildWhen: (prev, next) =>
                        prev.searchResults != next.searchResults ||
                        prev.conversations != next.conversations,
                    builder: (context, state) {
                      return _listWrapper(
                        context,
                        state.searchResults != null
                            ? state.searchResults!
                            : state.conversations,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: () => Navigator.pushNamed(context, newConversationRoute),
            // TODO: i18n
            label: const Text('Chat'),
            icon: const Icon(Icons.chat_outlined),
            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
            foregroundColor: Theme.of(context).colorScheme.onSecondaryContainer,
          ),
        ),
      ),
    );
  }
}
