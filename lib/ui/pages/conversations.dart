import 'package:flutter/material.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';
import 'package:moxxyv2/ui/widgets/conversation.dart';

import 'package:flutter_speed_dial/flutter_speed_dial.dart';

class ConversationsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
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
      body: ListView(
        children: [
          ConversationsListRow("https://external-content.duckduckgo.com/iu/?u=https%3A%2F%2Fyt3.ggpht.com%2Fa%2FAGF-l78YnmyE3snkHMp_18AZOP5QRH2WOYSBlnPKFA%3Ds900-c-k-c0xffffffff-no-rj-mo&f=1&nofb=1", "Ars Almal"),
          ConversationsListRow("https://external-content.duckduckgo.com/iu/?u=https%3A%2F%2Ftse4.mm.bing.net%2Fth%3Fid%3DOIP.N1bqs6sYnkcHO9cp4VY56ACwCw%26pid%3DApi&f=1", "Millie Parfait"),
          ConversationsListRow("", "Normal dude"),
        ]
      ),
      // TODO: Maybe don't use a SpeedDial
      floatingActionButton: SpeedDial(
        icon: Icons.chat,
        visible: true,
        curve: Curves.bounceInOut,
        children: [
          SpeedDialChild(
            child: Icon(Icons.person_add),
            onTap: () => Navigator.pushNamed(context, "/new_conversation"),
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
