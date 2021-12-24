import 'package:flutter/material.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';
import 'package:moxxyv2/ui/widgets/conversation.dart';
import 'package:moxxyv2/models/roster.dart';
import 'package:moxxyv2/models/conversation.dart';
import 'package:moxxyv2/redux/state.dart';
import 'package:moxxyv2/redux/conversations/actions.dart';
import 'package:moxxyv2/ui/pages/conversation.dart';
import 'package:moxxyv2/repositories/roster.dart';
import 'package:moxxyv2/ui/helpers.dart';

import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:get_it/get_it.dart';

typedef AddConversationFunction = void Function(Conversation conversation);

class _NewConversationViewModel {
  final AddConversationFunction addConversation;
  final List<Conversation> conversations;
  final List<RosterItem> roster;

  _NewConversationViewModel({ required this.conversations, required this.roster, required this.addConversation });
}

class NewConversationPage extends StatelessWidget {
  void _addNewContact(_NewConversationViewModel viewModel, BuildContext context, RosterItem rosterItem) {
    bool hasConversation = viewModel.conversations.length > 0 && viewModel.conversations.firstWhere((item) => item.jid == rosterItem.jid, orElse: null) != null;

    // Prevent adding the same conversation twice to the list of open conversations
    if (!hasConversation) {
      // TODO
      // TODO: Install a middleware to make sure that the conversation gets added to the
      //       repository. Also handle updates
      Conversation conversation = Conversation(
        title: rosterItem.title,
        jid: rosterItem.jid,
        lastMessageBody: "",
        avatarUrl: rosterItem.avatarUrl,
        unreadCounter: 0
      );
      viewModel.addConversation(conversation);
    }
        
    // TODO: Make sure that no conversation can be added twice
    Navigator.pushNamedAndRemoveUntil(
      context,
      "/conversation",
      ModalRoute.withName("/conversations"),
      arguments: ConversationPageArguments(jid: rosterItem.jid));
  }
  
  @override
  Widget build(BuildContext context) {
    var roster = GetIt.I.get<RosterRepository>().getAllRosterItems();
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: BorderlessTopbar(
          children: [
            BackButton(),
            Text(
              "Start new chat",
              style: TextStyle(
                fontSize: 17
              )
            )
          ]
        )
      ),
      body: StoreConnector<MoxxyState, _NewConversationViewModel>(
        converter: (store) => _NewConversationViewModel(
          addConversation: (c) => store.dispatch(
            AddConversationAction(
              title: c.title,
              avatarUrl: c.avatarUrl,
              lastMessageBody: c.lastMessageBody,
              jid: c.jid
            )
          ),
          conversations: store.state.conversations,
          roster: GetIt.I.get<RosterRepository>().getAllRosterItems()
        ),
        builder: (context, viewModel) => ListView.builder(
          itemCount: viewModel.roster.length + 2,
          itemBuilder: (context, index) {
            switch(index) {
              case 0: {
                return InkWell(
                  onTap: () => Navigator.pushNamed(context, "/new_conversation/add_contact"),
                  child: Row(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircleAvatar(
                          child: Icon(Icons.person_add),
                          radius: 35.0
                        )
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          "Add contact",
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold
                          )
                        )
                      )
                    ]
                  )
                );
              }
              break;
              case 1: {
                return InkWell(
                  onTap: () => showNotImplementedDialog("groupchat", context),
                  child: Row(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: CircleAvatar(
                          child: Icon(Icons.group_add),
                          radius: 35.0
                        )
                      ),
                      Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          "Create groupchat",
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.bold
                          )
                        )
                      )
                    ]
                  )
                );
              }
              break;
              default: {
                RosterItem item = viewModel.roster[index - 2];
                return InkWell(
                  onTap: () => this._addNewContact(viewModel, context, item),
                  child: ConversationsListRow(item.avatarUrl, item.title, item.jid, 0)
                );
              }
              break;
            }
          }
        )
      )
    );
  }
}
