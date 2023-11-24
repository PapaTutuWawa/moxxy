import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/models/conversation.dart';
import 'package:moxxyv2/ui/bloc/conversation_bloc.dart';
import 'package:moxxyv2/ui/bloc/conversations_bloc.dart';
import 'package:moxxyv2/ui/bloc/request_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/ui/post_build.dart';
import 'package:moxxyv2/ui/request_dialog.dart';
import 'package:moxxyv2/ui/widgets/avatar.dart';
import 'package:moxxyv2/ui/widgets/context_menu.dart';
import 'package:moxxyv2/ui/widgets/conversation_card.dart';

const double _accountListTileVerticalPadding = 8;
const double _accountListTilePictureHeight = 58;

class AccountListTile extends StatelessWidget {
  const AccountListTile({
    required this.displayName,
    required this.jid,
    required this.active,
    super.key,
  });

  /// The display name of the account
  final String displayName;

  /// The JID of the account.
  final String jid;

  /// Flag indicating whether the account is currently active.
  final bool active;

  static double get height => _accountListTileVerticalPadding * 2 + _accountListTilePictureHeight;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return InkWell(
      // TODO: OnTap
      onTap: () {},
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: _accountListTileVerticalPadding,
        ),
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Icon(
                active ? Icons.radio_button_on : Icons.radio_button_off,
                size: 20,
                color: active ? colorScheme.primary : colorScheme.onSurface,
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(
                right: 12,
              ),
              // TODO: Pass the JID of our different account here.
              child: SquircleCachingXMPPAvatar.self(
                size: _accountListTilePictureHeight,
                borderRadius: 12,
              ),
            ),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    displayName,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.inverseSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    jid,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(left: 24),
              child: IconButton(
                icon: Icon(
                  Icons.delete_outline,
                  size: 30,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
                onPressed: () {},
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
      onDismissed: (direction) => context.read<ConversationsBloc>().add(
            ConversationClosedEvent(widget.item.jid),
          ),
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
          name: conversationsRoute,
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
  double _topStackOffset = 0;

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
    super.dispose();
  }

  void dismissContextMenu() {
    _contextMenuController.reverse();
    setState(() {
      _selectedConversation = null;
    });
  }

  Widget _listWrapper(BuildContext context, ConversationsState state) {
    if (state.conversations.isNotEmpty) {
      return ListView.builder(
        itemCount: state.conversations.length,
        itemBuilder: (context, index) {
          final item = state.conversations[index];

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
            onTap: () {
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

                final widgetRect = getWidgetPositionOnScreen(key);
                final height = MediaQuery.of(context).size.height;

                setState(() {
                  _selectedConversation = item;

                  final numberOptions = item.numberContextMenuOptions;
                  if (height - widgetRect.bottom >
                      40 + numberOptions * ContextMenuItem.height) {
                    // In this case, we have enough space below the conversation item,
                    // so we say that the top of the context menu is
                    // widgetRect.bottom (Bottom y coordinate of the conversation item)
                    // minus 20 (padding so we're not directly against the conversation
                    // item) - the height of the top bar.
                    _topStackOffset = widgetRect.bottom - 20 - kToolbarHeight;
                  } else {
                    // In this case we don't have sufficient space below the conversation
                    // item, so we place the context menu above it.
                    // The computation is the same as in the above branch, but now
                    // we position the context menu above and thus also substract the
                    // height of the context menu
                    // (numberOptions * ContextMenuItem.height).
                    _topStackOffset = widgetRect.top -
                        20 -
                        numberOptions * ContextMenuItem.height -
                        kToolbarHeight;
                  }
                });

                await _contextMenuController.forward();
              },
              child: row,
            ),
          );
        },
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: paddingVeryLarge),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8),
            // TODO(Unknown): Maybe somehow render the svg
            child: Image.asset('assets/images/begin_chat.png'),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(t.pages.conversations.noOpenChats),
          ),
          TextButton(
            child: Text(t.pages.conversations.startChat),
            onPressed: () => Navigator.pushNamed(context, newConversationRoute),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PostBuildWidget(
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
        body: BlocBuilder<ConversationsBloc, ConversationsState>(
          builder: (BuildContext context, ConversationsState state) => Scaffold(
            appBar: AppBar(
              automaticallyImplyLeading: false,
              toolbarHeight: 70,
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // TODO: Fix padding
                  Padding(
                    padding: const EdgeInsets.only(right: 14),
                    child: SquircleCachingXMPPAvatar.self(
                      size: 50,
                      borderRadius: 30,
                      onTap: () {
                        // Compute the max extent.
                        final mq = MediaQuery.of(context);
                        // TODO: Pull this value from somewhere.
                        const numberAccounts = 3;
                        final extent = clampDouble(
                          // TODO: Update to 3.16 and use mq.textScaler.scale(20) to get the logical size?
                          (numberAccounts * AccountListTile.height + 80) / mq.size.height,
                          0,
                          0.9,
                        );

                        showModalBottomSheet<void>(
                          context: context,
                          showDragHandle: true,
                          isScrollControlled: true,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              topLeft: Radius.circular(28),
                              topRight: Radius.circular(28),
                            ),
                          ),
                          builder: (context) => DraggableScrollableSheet(
                            expand: false,
                            snap: true,
                            minChildSize: extent,
                            initialChildSize: extent,
                            maxChildSize: extent,
                            builder: (context, scrollController) => ListView(
                              controller: scrollController,
                              // Disable scrolling when we don't "fill" the screen.
                              physics: extent < 0.9
                                  ? const NeverScrollableScrollPhysics()
                                  : null,
                              children: [
                                // TODO: Actually load the accounts from somewhere
                                AccountListTile(
                                  displayName: state.displayName,
                                  jid: state.jid,
                                  active: true,
                                ),
                                // TODO: Remove
                                const AccountListTile(
                                  displayName: 'User-chan',
                                  jid: 'user@example.com',
                                  active: false,
                                ),
                                // TODO: Remove
                                const AccountListTile(
                                  displayName: 'Alt-tan',
                                  jid: 'alt@server.net',
                                  active: false,
                                ),
                                InkWell(
                                  onTap: () {},
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.add,
                                          size: 20,
                                          color: Theme.of(context)
                                              .colorScheme
                                              .onSurface,
                                        ),
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(left: 12),
                                          child: Text(
                                            // TODO: i18n
                                            "Add another account",
                                            style: TextStyle(
                                              fontSize: 20,
                                              height: 2,
                                              fontWeight: FontWeight.w600,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .inverseSurface,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  Text(
                    state.displayName,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.inverseSurface,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  icon: const Icon(
                    Icons.search,
                    size: 25,
                  ),
                  onPressed: () {},
                ),
                IconButton(
                  icon: const Icon(
                    Icons.settings_outlined,
                    size: 25,
                  ),
                  onPressed: () {
                    Navigator.pushNamed(context, settingsRoute);
                  },
                ),
              ],
            ),
            body: Stack(
              children: [
                _listWrapper(context, state),
                if (_selectedConversation != null)
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
                  left: 8,
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
                            onPressed: () {
                              context.read<ConversationsBloc>().add(
                                    ConversationMarkedAsReadEvent(
                                      _selectedConversation!.jid,
                                    ),
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
                              // ignore: use_build_context_synchronously
                              context.read<ConversationsBloc>().add(
                                    ConversationClosedEvent(
                                      _selectedConversation!.jid,
                                    ),
                                  );
                              dismissContextMenu();
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            floatingActionButton: FloatingActionButton.extended(
              onPressed: () =>
                  Navigator.pushNamed(context, newConversationRoute),
              // TODO: i18n
              label: const Text('Chat'),
              icon: const Icon(Icons.chat_outlined),
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              foregroundColor:
                  Theme.of(context).colorScheme.onSecondaryContainer,
            ),
          ),
        ),
      ),
    );
  }
}
