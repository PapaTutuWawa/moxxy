import "dart:async";

import "package:moxxyv2/ui/widgets/topbar.dart";
import "package:moxxyv2/ui/widgets/conversation.dart";
import "package:moxxyv2/ui/widgets/avatar.dart";
import "package:moxxyv2/ui/pages/conversation/arguments.dart";
import "package:moxxyv2/ui/pages/profile/profile.dart";
import "package:moxxyv2/models/conversation.dart";
import "package:moxxyv2/redux/state.dart";
import "package:moxxyv2/redux/conversation/actions.dart";
import "package:moxxyv2/ui/constants.dart";
import "package:moxxyv2/ui/helpers.dart";

import "package:flutter/material.dart";
import "package:flutter_speed_dial/flutter_speed_dial.dart";
import "package:flutter_redux_navigation/flutter_redux_navigation.dart";
import "package:flutter_redux/flutter_redux.dart";
import "package:redux/redux.dart";

class _ConversationsListViewModel {
  final List<Conversation> conversations;
  final String displayName;
  final String avatarUrl;
  final void Function(String) goToConversation;
  final void Function(Conversation) closeConversation;

  _ConversationsListViewModel({ required this.conversations, required this.displayName, required this.avatarUrl, required this.goToConversation, required this.closeConversation });
}

enum ConversationsOptions {
  SETTINGS
}

class ConversationsPage extends StatelessWidget {
  Widget _listWrapper(BuildContext context, _ConversationsListViewModel viewModel) {
    double maxTextWidth = MediaQuery.of(context).size.width * 0.6;

    if (viewModel.conversations.length > 0) {
      return ListView.builder(
        itemCount: viewModel.conversations.length,
        itemBuilder: (_context, index) {
          Conversation item = viewModel.conversations[index];
          return Dismissible(
            key: ValueKey("conversation;" + item.toString()),
            onDismissed: (direction) => viewModel.closeConversation(item),
            background: Container(
              color: Colors.red,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Icon(Icons.delete),
                    Spacer(),
                    Icon(Icons.delete)
                  ]
                )
              )
            ),
            child: InkWell(
              onTap: () => viewModel.goToConversation(item.jid),
              child: ConversationsListRow(
                item.avatarUrl,
                item.title,
                item.lastMessageBody,
                item.unreadCounter,
                maxTextWidth,
                item.lastChangeTimestamp,
                true,
                key: ValueKey("conversationRow;" + item.jid)
              )
            ) 
          );
        }
      );
    }

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: PADDING_VERY_LARGE),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Padding(
            padding: EdgeInsets.only(top: 8.0),
            // TODO: Maybe somehow render the svg
            child: Image.asset("assets/images/begin_chat.png")
          ),
          Padding(
            padding: EdgeInsets.only(top: 8.0),
            child: Text("You have no open chats")
          ),
          TextButton(
            child: Text("Start a chat"),
            onPressed: () => Navigator.pushNamed(context, "/new_conversation")
          )
        ]
      )
    );
  }

  @override
  Widget build(BuildContext buildContext) {
    return StoreConnector<MoxxyState, _ConversationsListViewModel>(
      converter: (store) => _ConversationsListViewModel(
        conversations: store.state.conversations.values.where((c) => c.open).toList(),
        displayName: store.state.accountState.displayName,
        avatarUrl: store.state.accountState.avatarUrl,
        goToConversation: (jid) => store.dispatch(NavigateToAction.push(
            "/conversation",
            arguments: ConversationPageArguments(jid: jid)
        )),
        closeConversation: (c) => store.dispatch(CloseConversationAction(jid: c.jid, id: c.id, redirect: false))
      ),
      builder: (context, viewModel) => Scaffold(
        appBar: BorderlessTopbar.avatarAndName(
          avatar: AvatarWrapper(
            radius: 20.0,
            avatarUrl: viewModel.avatarUrl,
            altIcon: Icons.person
          ),
          title: viewModel.displayName,
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
                PopupMenuItem(
                  value: ConversationsOptions.SETTINGS,
                  child: Text("Settings")
                )
              ]
            )
          ]
        ),
        body: this._listWrapper(context, viewModel),
        floatingActionButton: SpeedDial(
          icon: Icons.chat,
          visible: true,
          curve: Curves.bounceInOut,
          backgroundColor: PRIMARY_COLOR,
          // TODO: Theme dependent?
          foregroundColor: Colors.white,
          children: [
            SpeedDialChild(
              child: Icon(Icons.group),
              onTap: () => showNotImplementedDialog("groupchat", buildContext),
              backgroundColor: PRIMARY_COLOR,
              // TODO: Theme dependent?
              foregroundColor: Colors.white,
              label: "Join groupchat"
            ),
            SpeedDialChild(
              child: Icon(Icons.person_add),
              onTap: () => Navigator.pushNamed(buildContext, "/new_conversation"),
              backgroundColor: PRIMARY_COLOR,
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
