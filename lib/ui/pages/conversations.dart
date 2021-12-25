import 'package:flutter/material.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';
import 'package:moxxyv2/ui/widgets/conversation.dart';
import 'package:moxxyv2/ui/widgets/avatar.dart';
import 'package:moxxyv2/ui/pages/conversation/arguments.dart';
import 'package:moxxyv2/ui/pages/profile.dart';
import 'package:moxxyv2/models/conversation.dart';
import 'package:moxxyv2/redux/state.dart';
import 'package:moxxyv2/ui/constants.dart';
import "package:moxxyv2/ui/helpers.dart";

import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

class _ConversationsListViewModel {
  final List<Conversation> conversations;

  _ConversationsListViewModel({ required this.conversations });
}

enum ConversationsOptions {
  SETTINGS
}

class ConversationsPage extends StatelessWidget {
  @override
  Widget build(BuildContext buildContext) {
    return Scaffold(
      appBar: BorderlessTopbar.avatarAndName(
        avatar: AvatarWrapper(
          radius: 20.0,
          avatarUrl: "https://external-content.duckduckgo.com/iu/?u=https%3A%2F%2Ftse3.mm.bing.net%2Fth%3Fid%3DOIP.MkXhyVPrn9eQGC1CTOyTYAHaHa%26pid%3DApi&f=1",
          // TODO: Move the StoreConnector up a bit
          alt: Text("?")
        ),
        title: "Oujou",
        onTapFunction: () => Navigator.pushNamed(buildContext, "/conversation/profile", arguments: ProfilePageArguments(isSelfProfile: true)),
        showBackButton: false,
        extra: [
          PopupMenuButton(
            onSelected: (ConversationsOptions result) {
              if (result == ConversationsOptions.SETTINGS) {
                Navigator.pushNamed(buildContext, "/settings");
              }
            },
            icon: Icon(Icons.more_vert),
            itemBuilder: (BuildContext context) => [
              // TODO: Use enum
              PopupMenuItem(
                value: ConversationsOptions.SETTINGS,
                child: Text("Settings")
              )
            ]
          )
        ]
      ),
      body: StoreConnector<MoxxyState, _ConversationsListViewModel>(
        converter: (store) => _ConversationsListViewModel(
          conversations: store.state.conversations
        ),
        builder: (context, viewModel) => ListView.builder(
          itemCount: viewModel.conversations.length,
          itemBuilder: (_context, index) {
            Conversation item = viewModel.conversations[index];
            return InkWell(
              onTap: () => Navigator.pushNamed(buildContext, "/conversation", arguments: ConversationPageArguments(jid: item.jid)),
              child: ConversationsListRow(item.avatarUrl, item.title, item.lastMessageBody, item.unreadCounter)
            );
          }
        )
      ),
      // TODO: Maybe don't use a SpeedDial
      floatingActionButton: SpeedDial(
        icon: Icons.chat,
        visible: true,
        curve: Curves.bounceInOut,
        backgroundColor: BUBBLE_COLOR_SENT,
        // TODO: Theme dependent?
        foregroundColor: Colors.white,
        children: [
          SpeedDialChild(
            child: Icon(Icons.group),
            onTap: () => showNotImplementedDialog("groupchat", buildContext),
            backgroundColor: BUBBLE_COLOR_SENT,
            // TODO: Theme dependent?
            foregroundColor: Colors.white,
            label: "Join groupchat"
          ),
          SpeedDialChild(
            child: Icon(Icons.person_add),
            onTap: () => Navigator.pushNamed(buildContext, "/new_conversation"),
            backgroundColor: BUBBLE_COLOR_SENT,
            // TODO: Theme dependent?
            foregroundColor: Colors.white,
            label: "New chat"
          )
        ]
      ),
    );
  }
}
