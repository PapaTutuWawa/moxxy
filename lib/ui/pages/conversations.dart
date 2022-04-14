import "package:moxxyv2/shared/models/conversation.dart";
import "package:moxxyv2/ui/constants.dart";
import "package:moxxyv2/ui/helpers.dart";
import "package:moxxyv2/ui/widgets/topbar.dart";
import "package:moxxyv2/ui/widgets/conversation.dart";
import "package:moxxyv2/ui/widgets/avatar.dart";
import "package:moxxyv2/ui/bloc/conversations_bloc.dart";
import "package:moxxyv2/ui/bloc/conversation_bloc.dart";
import "package:moxxyv2/ui/bloc/profile_bloc.dart";
import "package:moxxyv2/xmpp/xeps/xep_0085.dart";

import "package:flutter/material.dart";
import "package:get_it/get_it.dart";
import "package:flutter_speed_dial/flutter_speed_dial.dart";
import "package:flutter_bloc/flutter_bloc.dart";

enum ConversationsOptions {
  settings
}

class ConversationsPage extends StatelessWidget {
  const ConversationsPage({ Key? key }) : super(key: key);

  static get route => MaterialPageRoute(builder: (context) => const ConversationsPage());
  
  Widget _listWrapper(BuildContext context, ConversationsState state) {
    double maxTextWidth = MediaQuery.of(context).size.width * 0.6;

    if (state.conversations.isNotEmpty) {
      return ListView.builder(
        itemCount: state.conversations.length,
        itemBuilder: (_context, index) {
          Conversation item = state.conversations[index];
          return Dismissible(
            key: ValueKey("conversation;" + item.toString()),
            onDismissed: (direction) => context.read<ConversationsBloc>().add(
              ConversationClosedEvent(item.jid)
            ),
            background: Container(
              color: Colors.red,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: const [
                    Icon(Icons.delete),
                    Spacer(),
                    Icon(Icons.delete)
                  ]
                )
              )
            ),
            child: InkWell(
              onTap: () => GetIt.I.get<ConversationBloc>().add(
                RequestedConversationEvent(item.jid, item.title, item.avatarUrl)
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
                key: ValueKey("conversationRow;" + item.jid)
              )
            ) 
          );
        }
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: paddingVeryLarge),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            // TODO: Maybe somehow render the svg
            child: Image.asset("assets/images/begin_chat.png")
          ),
          const Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text("You have no open chats")
          ),
          TextButton(
            child: const Text("Start a chat"),
            onPressed: () => Navigator.pushNamed(context, newConversationRoute)
          )
        ]
      )
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConversationsBloc, ConversationsState>(
      builder: (context, state) => Scaffold(
        appBar: BorderlessTopbar.avatarAndName(
          TopbarAvatarAndName(
            TopbarTitleText(state.displayName),
            Hero(
              tag: "self_profile_picture",
              child: Material(
                child: AvatarWrapper(
                  radius: 20.0,
                  avatarUrl: state.avatarUrl,
                  altIcon: Icons.person
                )
              )
            ),
            () => GetIt.I.get<ProfileBloc>().add(
              ProfilePageRequestedEvent(
                true,
                jid: state.jid,
                avatarUrl: state.avatarUrl,
                displayName: state.displayName
              )
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
                  const PopupMenuItem(
                    value: ConversationsOptions.settings,
                    child: Text("Settings")
                  )
                ]
              )
            ]
          )
        ),
        body: _listWrapper(context, state),
        floatingActionButton: SpeedDial(
          icon: Icons.chat,
          visible: true,
          curve: Curves.bounceInOut,
          backgroundColor: primaryColor,
          // TODO: Theme dependent?
          foregroundColor: Colors.white,
          children: [
            SpeedDialChild(
              child: const Icon(Icons.group),
              onTap: () => showNotImplementedDialog("groupchat", context),
              backgroundColor: primaryColor,
              // TODO: Theme dependent?
              foregroundColor: Colors.white,
              label: "Join groupchat"
            ),
            SpeedDialChild(
              child: const Icon(Icons.person_add),
              onTap: () => Navigator.pushNamed(context, newConversationRoute),
              backgroundColor: primaryColor,
              // TODO: Theme dependent?
              foregroundColor: Colors.white,
              label: "New chat"
            )
          ]
        )
      )
    );
  }
}
