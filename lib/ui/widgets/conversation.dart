import 'package:flutter/material.dart';

import "package:moxxyv2/ui/constants.dart";

import 'package:badges/badges.dart';

class ConversationsListRow extends StatelessWidget {
  String avatarUrl;
  String name;
  String lastMessageBody;
  int unreadCount;

  ConversationsListRow(this.avatarUrl, this.name, this.lastMessageBody, this.unreadCount);

  Widget _buildAvatar() {
    if (this.avatarUrl != "") {
      return CircleAvatar(
        // TODO
        backgroundImage: NetworkImage(this.avatarUrl),
        radius: 35.0
      );
    } else {
      return CircleAvatar(
        backgroundColor: Colors.grey,
        child: Text(this.name[0]),
        radius: 35.0
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    String badgeText = this.unreadCount > 99 ? "99+" : this.unreadCount.toString();

    return Row(
      children: [
        Padding(
          padding: EdgeInsets.all(8.0),
          child: this._buildAvatar()
        ),
        Padding(
          padding: EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                this.name,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
              // TODO: Change color, font size and truncate the text when too long
              Text(this.lastMessageBody)
            ]
          )
        ),
        Spacer(),
        Visibility(
          visible: this.unreadCount > 0,
          child: Badge(
            badgeContent: Text(badgeText),
            badgeColor: BUBBLE_COLOR_SENT
          )
        )
      ]
    );
  }
}
