import "dart:collection";

import "package:moxxyv2/ui/widgets/topbar.dart";
import "package:moxxyv2/ui/widgets/conversation.dart";
import "package:moxxyv2/ui/widgets/avatar.dart";
import "package:moxxyv2/models/roster.dart";
import "package:moxxyv2/models/conversation.dart";
import "package:moxxyv2/redux/state.dart";
import "package:moxxyv2/redux/conversations/actions.dart";
import "package:moxxyv2/ui/pages/conversation/arguments.dart";
import "package:moxxyv2/repositories/roster.dart";
import "package:moxxyv2/ui/helpers.dart";
import "package:moxxyv2/helpers.dart";
import "package:moxxyv2/constants.dart";

import "package:get_it/get_it.dart";
import "package:flutter/material.dart";
import "package:flutter_redux/flutter_redux.dart";
import "package:redux/redux.dart";

class _NewConversationViewModel {
  final void Function(String, String, String, String) addConversation;
  final List<Conversation> conversations;
  final List<RosterItem> roster;

  _NewConversationViewModel({ required this.conversations, required this.roster, required this.addConversation });
}

class NewConversationPage extends StatelessWidget {
  void _addNewConversation(_NewConversationViewModel viewModel, BuildContext context, RosterItem rosterItem) {
    viewModel.addConversation(
      rosterItem.title,
      rosterItem.avatarUrl,
      "",
      rosterItem.jid
    );
  }
  
  @override
  Widget build(BuildContext context) {
    double maxTextWidth = MediaQuery.of(context).size.width * 0.6;
    return Scaffold(
      appBar: BorderlessTopbar.simple(title: "Start new chat"),
      body: StoreConnector<MoxxyState, _NewConversationViewModel>(
        converter: (store) => _NewConversationViewModel(
          addConversation: (String title, String avatarUrl, String body, String jid) => store.dispatch(
            AddConversationFromUIAction(
              title: title,
              avatarUrl: avatarUrl,
              lastMessageBody: body,
              jid: jid
            )
          ),
          conversations: store.state.conversations,
          roster: store.state.roster
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
                        child: AvatarWrapper(
                          radius: 35.0,
                          alt: Icon(Icons.person_add)
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
                        child: AvatarWrapper(
                          radius: 35.0,
                          alt: Icon(Icons.group_add)
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
                return Dismissible(
                  key: ValueKey("roster;" + item.jid),
                  // TODO: This is bad and doesn't work
                  // WHY DIDN'T I WRITE IT USING AN ACTION AT FIRST
                  onDismissed: (direction) => GetIt.I.get<RosterRepository>().removeFromRoster(item),
                  background: Container(color: Colors.red),
                  child: InkWell(
                    onTap: () => this._addNewConversation(viewModel, context, item),
                    child: ConversationsListRow(item.avatarUrl, item.title, item.jid, 0, maxTextWidth, TIMESTAMP_NEVER, false)
                  )
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
