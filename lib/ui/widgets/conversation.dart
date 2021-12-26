import "package:flutter/material.dart";

import "package:moxxyv2/ui/constants.dart";
import "package:moxxyv2/ui/widgets/avatar.dart";
import "package:moxxyv2/helpers.dart";

import "package:badges/badges.dart";

// TODO: Use a Timer.periodic to update the timestamp every minute
class ConversationsListRow extends StatelessWidget {
  final String avatarUrl;
  final String name;
  final String lastMessageBody;
  final int unreadCount;
  final double maxTextWidth;

  ConversationsListRow(this.avatarUrl, this.name, this.lastMessageBody, this.unreadCount, this.maxTextWidth);
  
  @override
  Widget build(BuildContext context) {
    String badgeText = this.unreadCount > 99 ? "99+" : this.unreadCount.toString();

    return Stack(
      children: [
        Row(
          children: [
            Padding(
              padding: EdgeInsets.all(8.0),
              child: AvatarWrapper(
                radius: 35.0,
                avatarUrl: this.avatarUrl,
                // TODO: Clamp
                alt: Text(this.name[0] + this.name[1])
              )
            ),
            Padding(
              padding: EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: this.maxTextWidth
                    ),
                    child: Text(
                      this.name,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis
                    )
                  ),
                  // TODO: Change color and font size
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: this.maxTextWidth
                    ),

                    child: Text(
                      this.lastMessageBody,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis
                    )
                  )
                ]
              )
            ),
            Spacer(),
            Visibility(
              visible: this.unreadCount > 0,
              child: Padding(
                padding: EdgeInsetsDirectional.only(end: 8.0),
                child: Badge(
                  badgeContent: Text(badgeText),
                  badgeColor: BUBBLE_COLOR_SENT
                )
              )
            )
          ]
        ),
        Visibility(
          // TODO
          //visible: this.lastChangeTimestamp >= 0,
          visible: true,
          child: Positioned(
            top: 8,
            right: 8,
            child: Text(
              formatConversationTimestamp(
                DateTime(2021, 12, 26, 12, 20, 0, 0, 0).millisecondsSinceEpoch,
                DateTime.now().millisecondsSinceEpoch
              )
            )
          )
        ) 
      ]
    );
  }
}
