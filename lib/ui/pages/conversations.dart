import 'package:flutter/material.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';
import 'package:moxxyv2/ui/widgets/conversation.dart';
import 'package:moxxyv2/ui/pages/conversation.dart';
import 'package:moxxyv2/models/conversation.dart';
import 'package:moxxyv2/redux/state.dart';

import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

class _ConversationsListViewModel {
  final List<Conversation> conversations;

  _ConversationsListViewModel({ required this.conversations });
}

class ConversationsPage extends StatelessWidget {
  @override
  Widget build(BuildContext buildContext) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: BorderlessTopbar(
          children: [
            Padding(
              padding: EdgeInsets.only(right: 3.0),
              child: CircleAvatar(
                backgroundImage: NetworkImage("https://external-content.duckduckgo.com/iu/?u=https%3A%2F%2Ftse3.mm.bing.net%2Fth%3Fid%3DOIP.MkXhyVPrn9eQGC1CTOyTYAHaHa%26pid%3DApi&f=1"),
                radius: 20.0
              )
            ),
            Text(
              "Ojou",
              style: TextStyle(
                fontSize: 18
              )
            ),
            Spacer(),
            Center(
              child: InkWell(
                // TODO: Implement
                onTap: () {},
                // TODO: Find a better icon
                child: Icon(Icons.menu)
              )
            )
          ]
        )
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
              child: ConversationsListRow(item.avatarUrl, item.title, item.lastMessageBody)
            );
          }
        )
      ),
      // TODO: Maybe don't use a SpeedDial
      floatingActionButton: SpeedDial(
        icon: Icons.chat,
        visible: true,
        curve: Curves.bounceInOut,
        children: [
          SpeedDialChild(
            child: Icon(Icons.person_add),
            onTap: () => Navigator.pushNamed(buildContext, "/new_conversation"),
            label: "Add contact"
          ),
          SpeedDialChild(
            child: Icon(Icons.group_add),
            onTap: () => print("OK"),
            label: "Create groupchat"
          ),
          SpeedDialChild(
            child: Icon(Icons.group),
            onTap: () => print("OK"),
            label: "Join groupchat"
          )
        ]
      ),
    );
  }
}
