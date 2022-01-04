import 'package:flutter/material.dart';
import "dart:collection";
import 'package:moxxyv2/ui/widgets/topbar.dart';
import 'package:moxxyv2/ui/widgets/conversation.dart';
import 'package:moxxyv2/ui/widgets/avatar.dart';
import 'package:moxxyv2/models/roster.dart';
import 'package:moxxyv2/models/conversation.dart';
import 'package:moxxyv2/redux/state.dart';
import 'package:moxxyv2/redux/conversations/actions.dart';
import 'package:moxxyv2/ui/pages/conversation/arguments.dart';
import 'package:moxxyv2/repositories/roster.dart';
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/helpers.dart';
import 'package:moxxyv2/constants.dart';

import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

typedef AddConversationFunction = void Function(Conversation conversation);

class _NewConversationViewModel {
  final AddConversationFunction addConversation;
  final List<Conversation> conversations;
  final List<RosterItem> roster;

  _NewConversationViewModel({ required this.conversations, required this.roster, required this.addConversation });
}

class NewConversationPage extends StatelessWidget {
  void _addNewConversation(_NewConversationViewModel viewModel, BuildContext context, RosterItem rosterItem) {
    // NOTE: If the list of conversations is empty, then everything is fine. But if not, then
    //       firstWhere can throw if it does not find anything. So just wrap it in a try-catch
    bool hasConversation = viewModel.conversations.length > 0 && listContains(viewModel.conversations, (Conversation item) => item.jid == rosterItem.jid);

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
        unreadCounter: 0,
        // TODO: Make this List empty
        sharedMediaPaths: [
          "https://external-content.duckduckgo.com/iu/?u=https%3A%2F%2Fi.redd.it%2Fv2ybdgx5cow61.jpg&f=1&nofb=1",
          "https://ih1.redbubble.net/image.1660387906.9194/bg,f8f8f8-flat,750x,075,f-pad,750x1000,f8f8f8.jpg",
          "https://external-content.duckduckgo.com/iu/?u=https%3A%2F%2Fcdn.donmai.us%2Fsample%2Fb6%2Fe6%2Fsample-b6e62e3edc1c6dfe6afdb54614b4a710.jpg&f=1&nofb=1",
          "https://external-content.duckduckgo.com/iu/?u=https%3A%2F%2F64.media.tumblr.com%2Fec84dc5628ca3d8405374b85a51c7328%2Fbb0fc871a5029726-04%2Fs1280x1920%2Ffa6d89e8a2c2f3ce17465d328c2fe0ed6c951f01.jpg&f=1&nofb=1"
        ],
        lastChangeTimestamp: TIMESTAMP_NEVER,
        id: viewModel.conversations.length,
        open: true
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
    double maxTextWidth = MediaQuery.of(context).size.width * 0.6;
    return Scaffold(
      appBar: BorderlessTopbar.simple(title: "Start new chat"),
      body: StoreConnector<MoxxyState, _NewConversationViewModel>(
        converter: (store) => _NewConversationViewModel(
          addConversation: (c) => store.dispatch(
            AddConversationFromUIAction(
              title: c.title,
              avatarUrl: c.avatarUrl,
              lastMessageBody: c.lastMessageBody,
              jid: c.jid
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
                return InkWell(
                  onTap: () => this._addNewConversation(viewModel, context, item),
                  child: ConversationsListRow(item.avatarUrl, item.title, item.jid, 0, maxTextWidth, TIMESTAMP_NEVER, false)
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
