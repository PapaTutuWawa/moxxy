import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/models/conversation.dart';
import 'package:moxxyv2/ui/bloc/conversation_bloc.dart';
import 'package:moxxyv2/ui/bloc/conversations_bloc.dart';
import 'package:moxxyv2/ui/bloc/profile_bloc.dart' as profile;
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/ui/widgets/avatar.dart';
import 'package:moxxyv2/ui/widgets/conversation.dart';
import 'package:moxxyv2/ui/widgets/overview_menu.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';

enum ConversationsOptions {
  settings
}

class ConversationsRowDismissible extends StatefulWidget {
  const ConversationsRowDismissible({
    required this.item,
    required this.child,
    super.key,
  });
  final Conversation item;
  final Widget child;

  @override
  ConversationsRowDismissibleState createState() => ConversationsRowDismissibleState();
}

class ConversationsRowDismissibleState extends State<ConversationsRowDismissible> {
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
  const ConversationsPage({ super.key });

  static MaterialPageRoute<dynamic> get route => MaterialPageRoute<dynamic>(
    builder: (context) => const ConversationsPage(),
    settings: const RouteSettings(
      name: conversationsRoute,
    ),
  );

  @override
  ConversationsPageState createState() => ConversationsPageState();
}

class ConversationsPageState extends State<ConversationsPage> with TickerProviderStateMixin {
  late final AnimationController _controller; 
  late Animation<double> _convY;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }
  
  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _listWrapper(BuildContext context, ConversationsState state) {
    final maxTextWidth = MediaQuery.of(context).size.width * 0.6;

    if (state.conversations.isNotEmpty) {
      return ListView.builder(
        itemCount: state.conversations.length,
        itemBuilder: (context, index) {
          final item = state.conversations[index];
          final row = ConversationsListRow(
            maxTextWidth,
            item,
            true,
            enableAvatarOnTap: true,
            key: ValueKey('conversationRow;${item.jid}'),
          );

          return ConversationsRowDismissible(
            item: item,
            child: GestureDetector(
              onLongPressStart: (event) async {
                Vibrate.feedback(FeedbackType.medium);
                
                _convY = Tween<double>(
                  begin: event.globalPosition.dy - 20,
                  end: 200,
                ).animate(
                  CurvedAnimation(
                    parent: _controller,
                    curve: Curves.easeInOutCubic,
                  ),
                );
                
                await _controller.forward();

                // ignore: use_build_context_synchronously
                await showDialog<void>(
                  context: context,
                  builder: (context) => OverviewMenu(
                    _convY,
                    highlight: row,
                    left: 0,
                    right: 0,
                    children: [
                      ...item.unreadCounter != 0 ? [
                        OverviewMenuItem(
                          icon: Icons.done_all,
                          text: t.pages.conversations.markAsRead,
                          onPressed: () {
                            context.read<ConversationsBloc>().add(
                              ConversationMarkedAsReadEvent(item.jid),
                            );
                            Navigator.of(context).pop();
                          },
                        ),
                      ] : [],
                      OverviewMenuItem(
                        icon: Icons.close,
                        text: t.pages.conversations.closeChat,
                        onPressed: () async {
                          // ignore: use_build_context_synchronously
                          final result = await showConfirmationDialog(
                            t.pages.conversations.closeChat,
                            t.pages.conversations.closeChatBody(
                              conversationTitle: item.title,
                            ),
                            context,
                          );

                          if (result) {
                            // TODO(Unknown): Show a snackbar allowing the user to revert the action
                            // ignore: use_build_context_synchronously
                            context.read<ConversationsBloc>().add(
                              ConversationClosedEvent(item.jid),
                            );

                            // ignore: use_build_context_synchronously
                            Navigator.of(context).pop();
                          }
                        },
                      ),
                    ],
                  ),
                );

                await _controller.reverse();
              },
              child: InkWell(
                onTap: () => GetIt.I.get<ConversationBloc>().add(
                  RequestedConversationEvent(item.jid, item.title, item.avatarUrl),
                ),
                child: row,
              ),
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
          )
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConversationsBloc, ConversationsState>(
      builder: (BuildContext context, ConversationsState state) => Scaffold(
        appBar: BorderlessTopbar.avatarAndName(
          TopbarAvatarAndName(
            TopbarTitleText(state.displayName),
            Hero(
              tag: 'self_profile_picture',
              child: Material(
                color: const Color.fromRGBO(0, 0, 0, 0),
                child: AvatarWrapper(
                  radius: 20,
                  avatarUrl: state.avatarUrl,
                  altIcon: Icons.person,
                ),
              ),
            ),
            () => GetIt.I.get<profile.ProfileBloc>().add(
              profile.ProfilePageRequestedEvent(
                true,
                jid: state.jid,
                avatarUrl: state.avatarUrl,
                displayName: state.displayName,
              ),
            ),
            showBackButton: false,
            extra: [
              PopupMenuButton(
                onSelected: (ConversationsOptions result) {
                  switch (result) {
                    case ConversationsOptions.settings: Navigator.pushNamed(context, settingsRoute);
                    break;
                  }
                },
                icon: const Icon(Icons.more_vert),
                itemBuilder: (BuildContext context) => [
                  PopupMenuItem(
                    value: ConversationsOptions.settings,
                    child: Text(t.pages.conversations.overlaySettings),
                  )
                ],
              )
            ],
          ),
        ),
        body: _listWrapper(context, state),
        floatingActionButton: SpeedDial(
          icon: Icons.chat,
          curve: Curves.bounceInOut,
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          children: [
            SpeedDialChild(
              child: const Icon(Icons.group),
              onTap: () => showNotImplementedDialog('groupchat', context),
              backgroundColor: primaryColor,
              // TODO(Unknown): Theme dependent?
              foregroundColor: Colors.white,
              label: t.pages.conversations.speeddialJoinGroupchat,
            ),
            SpeedDialChild(
              child: const Icon(Icons.person_add),
              onTap: () => Navigator.pushNamed(context, newConversationRoute),
              backgroundColor: primaryColor,
              // TODO(Unknown): Theme dependent?
              foregroundColor: Colors.white,
              label: t.pages.conversations.speeddialNewChat,
            )
          ],
        ),
      ),
    );
  }
}
