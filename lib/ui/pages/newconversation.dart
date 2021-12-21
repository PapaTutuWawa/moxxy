import 'package:flutter/material.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';

class NewConversationPage extends StatelessWidget {
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
      body: ListView(
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
          Row(
            children: [
              Padding(
                padding: EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundImage: NetworkImage("https://vignette.wikia.nocookie.net/virtualyoutuber/images/4/4e/Houshou_Marine_-_Portrait.png/revision/latest?cb=20190821035347"),
                  radius: 35.0
                )
              ),
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Column (
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Houshou Marine",
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold
                      )
                    ),
                    Text("houshou.marine@hololive.tv")
                  ]
                )
              )
            ]
          )
        ]
      )
    );
  }
}
