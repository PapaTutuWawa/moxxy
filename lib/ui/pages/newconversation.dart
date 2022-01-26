import "package:moxxyv2/ui/widgets/topbar.dart";
import "package:moxxyv2/ui/widgets/conversation.dart";
import "package:moxxyv2/ui/widgets/avatar.dart";
import "package:moxxyv2/ui/helpers.dart";
import "package:moxxyv2/ui/constants.dart";
import "package:moxxyv2/shared/models/roster.dart";
import "package:moxxyv2/shared/models/conversation.dart";
import "package:moxxyv2/ui/redux/state.dart";
import "package:moxxyv2/ui/redux/roster/actions.dart";
import "package:moxxyv2/ui/redux/conversation/actions.dart";
import "package:moxxyv2/shared/constants.dart";

import "package:flutter/material.dart";
import "package:flutter_redux/flutter_redux.dart";

class _NewConversationViewModel {
  final void Function(String, String, String, String) addConversation;
  final void Function(String) removeRosterItem;
  final List<Conversation> conversations;
  final List<RosterItem> roster;

  const _NewConversationViewModel({ required this.conversations, required this.roster, required this.addConversation, required this.removeRosterItem });
}

class NewConversationPage extends StatelessWidget {
  const NewConversationPage({ Key? key }) : super(key: key);

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
          removeRosterItem: (jid) => store.dispatch(RemoveRosterItemUIAction(jid: jid)),
          conversations: store.state.conversations.values.toList(),
          roster: store.state.roster
        ),
        builder: (context, viewModel) => ListView.builder(
          itemCount: viewModel.roster.length + 2,
          itemBuilder: (context, index) {
            switch(index) {
              case 0:
                return InkWell(
                  onTap: () => Navigator.pushNamed(context, addContactRoute),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: AvatarWrapper(
                          radius: 35.0,
                          alt: const Icon(Icons.person_add)
                        )
                      ),
                      const Padding(
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
              case 1:
                return InkWell(
                  onTap: () => showNotImplementedDialog("groupchat", context),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: AvatarWrapper(
                          radius: 35.0,
                          alt: const Icon(Icons.group_add)
                        )
                      ),
                      const Padding(
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
              default:
                RosterItem item = viewModel.roster[index - 2];
                return Dismissible(
                  key: ValueKey("roster;" + item.jid),
                  onDismissed: (direction) => viewModel.removeRosterItem(item.jid),
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
                    onTap: () => _addNewConversation(viewModel, context, item),
                    child: ConversationsListRow(item.avatarUrl, item.title, item.jid, 0, maxTextWidth, timestampNever, false)
                  )
                );
            }
          }
        )
      )
    );
  }
}
