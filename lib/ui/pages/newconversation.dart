import 'package:flutter/material.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';
import 'package:moxxyv2/ui/widgets/conversation.dart';
import 'package:moxxyv2/models/conversation.dart';
import 'package:moxxyv2/redux/state.dart';
import 'package:moxxyv2/redux/conversations/actions.dart';

import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';

typedef AddConversationFunction = void Function(String title, String avatarUrl);

class _NewConversationViewModel {
  final AddConversationFunction addConversation;

  _NewConversationViewModel({ required this.addConversation });
}

class NewConversationPage extends StatelessWidget {
  void _addNewContact(_NewConversationViewModel viewModel, BuildContext context, String name, String avatarUrl) {
    viewModel.addConversation(name, avatarUrl);
    // TODO
    Navigator.pushNamedAndRemoveUntil(context, "/conversation", ModalRoute.withName("/conversations"));
  }
  
  @override
  Widget build(BuildContext context) {
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
          addConversation: (title, avatarUrl) => store.dispatch(
            AddConversationAction(
              title: title,
              avatarUrl: avatarUrl,
              lastMessageBody: ""
            )
          )
        ),
        // TODO: Use ListView.builder
        builder: (context, viewModel) => ListView(
          children: [
            InkWell(
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
            ),
            Row(
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
            ),
            InkWell(
              onTap: () => this._addNewContact(viewModel, context, "Houshou Marine", "https://vignette.wikia.nocookie.net/virtualyoutuber/images/4/4e/Houshou_Marine_-_Portrait.png/revision/latest?cb=20190821035347"),
              child: ConversationsListRow("https://vignette.wikia.nocookie.net/virtualyoutuber/images/4/4e/Houshou_Marine_-_Portrait.png/revision/latest?cb=20190821035347", "Houshou Marine", "houshou.marine@hololive.tv")
            ) 
          ]
        )
      )
    );
  }
}
