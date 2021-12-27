import "dart:async";
import 'package:flutter/material.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';
import 'package:moxxyv2/ui/widgets/conversation.dart';
import 'package:moxxyv2/ui/widgets/avatar.dart';
import 'package:moxxyv2/ui/pages/conversation/arguments.dart';
import 'package:moxxyv2/ui/pages/profile/profile.dart';
import 'package:moxxyv2/models/conversation.dart';
import 'package:moxxyv2/redux/state.dart';
import 'package:moxxyv2/ui/constants.dart';
import "package:moxxyv2/ui/helpers.dart";

import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

class _ListViewWrapperViewModel {
  final List<Conversation> conversations;

  _ListViewWrapperViewModel({ required this.conversations });
}

// NOTE: Q: Why wrap the ListView? A: So we can update it every minute to update the timestamps
// TODO: Replace with something better
class _ListViewWrapperState extends State<ListViewWrapper> {
  Timer? _updateTimer;
  int _tickCounter = 0;

  _ListViewWrapperState() {
    this._updateTimer = Timer.periodic(Duration(minutes: 1), this._timerCallback);
  }
  
  void _timerCallback(Timer timer) {
    print("TOCK");
    setState(() {
        this._tickCounter++;
    }); 
  }

  @override
  void dispose() {
    super.dispose();
    if (this._updateTimer != null) {
      this._updateTimer!.cancel();
    }
  }
  
  @override
  Widget build(BuildContext build) {
    return StoreConnector<MoxxyState, _ListViewWrapperViewModel>(
      converter: (store) => _ListViewWrapperViewModel(
        // TODO: Sort conversations by timestamp
        conversations: store.state.conversations,
      builder: (context, viewModel) {
        double maxTextWidth = MediaQuery.of(context).size.width * 0.6;

        return ListView.builder(
          itemCount: viewModel.conversations.length,
          itemBuilder: (_context, index) {
            Conversation item = viewModel.conversations[index];
            return InkWell(
              onTap: () => Navigator.pushNamed(context, "/conversation", arguments: ConversationPageArguments(jid: item.jid)),
              child: ConversationsListRow(item.avatarUrl, item.title, item.lastMessageBody, item.unreadCounter, maxTextWidth, item.lastChangeTimestamp)
            );
          }
        );
      }
    );
  }
}

class ListViewWrapper extends StatefulWidget {
  ListViewWrapper();

  @override
  _ListViewWrapperState createState() => _ListViewWrapperState();
}

class _ConversationsListViewModel {
  final List<Conversation> conversations;
  final String displayName;
  final String avatarUrl;

  _ConversationsListViewModel({ required this.conversations, required this.displayName, required this.avatarUrl });
}

enum ConversationsOptions {
  SETTINGS
}

class ConversationsPage extends StatelessWidget {
  Widget _listWrapper(BuildContext context, _ConversationsListViewModel viewModel) {
    if (viewModel.conversations.length > 0) {
      return ListViewWrapper();
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
        conversations: store.state.conversations,
        displayName: store.state.accountState.displayName,
        avatarUrl: store.state.accountState.avatarUrl
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
                // TODO: Use enum
                PopupMenuItem(
                  value: ConversationsOptions.SETTINGS,
                  child: Text("Settings")
                )
              ]
            )
          ]
        ),
        body: this._listWrapper(context, viewModel),
        // TODO: Maybe don't use a SpeedDial
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
