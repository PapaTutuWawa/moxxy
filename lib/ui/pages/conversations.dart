import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/ui/bloc/conversation_bloc.dart';
import 'package:moxxyv2/ui/bloc/conversations_bloc.dart';
import 'package:moxxyv2/ui/bloc/profile_bloc.dart' as profile;
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/ui/widgets/avatar.dart';
import 'package:moxxyv2/ui/widgets/conversation.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';

enum ConversationsOptions {
  settings
}

class ConversationsPage extends StatelessWidget {
  const ConversationsPage({ super.key });

  static MaterialPageRoute<dynamic> get route => MaterialPageRoute<dynamic>(
    builder: (context) => const ConversationsPage(),
    settings: const RouteSettings(
      name: conversationsRoute,
    ),
  );
  
  Widget _listWrapper(BuildContext context, ConversationsState state) {
    final maxTextWidth = MediaQuery.of(context).size.width * 0.6;

    if (state.conversations.isNotEmpty) {
      return ListView.builder(
        itemCount: state.conversations.length,
        itemBuilder: (_context, index) {
          final item = state.conversations[index];
          return Dismissible(
            key: ValueKey('conversation;$item'),
            onDismissed: (direction) => context.read<ConversationsBloc>().add(
              ConversationClosedEvent(item.jid),
            ),
            background: ColoredBox(
              color: Colors.red,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: const [
                    Icon(Icons.delete),
                    Spacer(),
                    Icon(Icons.delete)
                  ],
                ),
              ),
            ),
            child: InkWell(
              onTap: () => GetIt.I.get<ConversationBloc>().add(
                RequestedConversationEvent(item.jid, item.title, item.avatarUrl),
              ),
              child: ConversationsListRow(
                item.avatarUrl,
                item.title,
                item.lastMessageBody,
                item.unreadCounter,
                maxTextWidth,
                item.lastChangeTimestamp,
                true,
                typingIndicator: item.chatState == ChatState.composing,
                key: ValueKey('conversationRow;${item.jid}'),
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
          // TODO(Unknown): Theme dependent?
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
