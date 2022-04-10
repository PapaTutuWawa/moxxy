import "package:moxxyv2/ui/helpers.dart";
import "package:moxxyv2/ui/constants.dart";
import "package:moxxyv2/ui/bloc/newconversation_bloc.dart";
import "package:moxxyv2/ui/widgets/topbar.dart";
import "package:moxxyv2/ui/widgets/conversation.dart";
import "package:moxxyv2/ui/widgets/avatar.dart";
import "package:moxxyv2/shared/models/roster.dart";
import "package:moxxyv2/shared/models/conversation.dart";
import "package:moxxyv2/shared/constants.dart";

import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";

class NewConversationPage extends StatelessWidget {
  const NewConversationPage({ Key? key }) : super(key: key);

  /*
  void _addNewConversation(_NewConversationViewModel viewModel, BuildContext context, RosterItem rosterItem) {
    viewModel.addConversation(
      rosterItem.title,
      rosterItem.avatarUrl,
      "",
      rosterItem.jid
    );
  }
  */

  Widget _renderIconEntry(Icon icon, String text, void Function() onTap) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: AvatarWrapper(
              radius: 35.0,
              alt: icon
            )
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold
              )
            )
          )
        ]
      )
    );
  }
  
  @override
  Widget build(BuildContext context) {
    double maxTextWidth = MediaQuery.of(context).size.width * 0.6;
    return Scaffold(
      appBar: BorderlessTopbar.simple("Start new chat"),
      body: BlocBuilder<NewConversationBloc, NewConversationState>(
        builder: (context, state) => ListView.builder(
          itemCount: state.roster.length + 2,
          itemBuilder: (context, index) {
            switch(index) {
              case 0: return _renderIconEntry(
                const Icon(Icons.person_add),
                "Add contact",
                () => Navigator.pushNamed(context, addContactRoute)
              );
              case 1: return _renderIconEntry(
                const Icon(Icons.group_add),
                "Create groupchat",
                () => showNotImplementedDialog("groupchat", context)
              );
              default:
                RosterItem item = state.roster[index - 2];
                return Dismissible(
                  key: ValueKey("roster;" + item.jid),
                  onDismissed: (_) => context.read<NewConversationBloc>().add(
                    NewConversationRosterItemRemovedEvent(item.jid)
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
                    onTap: () => context.read<NewConversationBloc>().add(
                      NewConversationAddedEvent(
                        item.jid,
                        item.title,
                        item.avatarUrl
                      )
                    ),
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
