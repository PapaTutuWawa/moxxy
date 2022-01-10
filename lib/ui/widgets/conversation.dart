import "dart:async";

import "package:moxxyv2/ui/constants.dart";
import "package:moxxyv2/ui/widgets/avatar.dart";
import "package:moxxyv2/helpers.dart";
import "package:moxxyv2/constants.dart";

import "package:flutter/material.dart";
import "package:badges/badges.dart";

class ConversationsListRow extends StatefulWidget {
  final String avatarUrl;
  final String name;
  final String lastMessageBody;
  final int unreadCount;
  final double maxTextWidth;
  final int lastChangeTimestamp;
  final bool update; // Should a timer run to update the timestamp
  
  ConversationsListRow(this.avatarUrl, this.name, this.lastMessageBody, this.unreadCount, this.maxTextWidth, this.lastChangeTimestamp, this.update, { Key? key }) : super(key: key);

  @override
  _ConversationsListRowState createState() => _ConversationsListRowState(
    this.avatarUrl,
    this.name,
    this.lastMessageBody,
    this.unreadCount,
    this.maxTextWidth,
    this.lastChangeTimestamp,
    this.update
  );
}

class _ConversationsListRowState extends State<ConversationsListRow> {
  final String avatarUrl;
  final String name;
  final String lastMessageBody;
  final int unreadCount;
  final double maxTextWidth;
  final int lastChangeTimestamp;

  late String _timestampString;
  late Timer? _updateTimer;
  
  _ConversationsListRowState(this.avatarUrl, this.name, this.lastMessageBody, this.unreadCount, this.maxTextWidth, this.lastChangeTimestamp, bool update) {
    final _now = DateTime.now().millisecondsSinceEpoch;

    this._timestampString = formatConversationTimestamp(
      this.lastChangeTimestamp,
      _now
    );

    // NOTE: We could also check and run the timer hourly, but who has a messenger on the
    //       conversation screen open for hours on end?
    if (update && lastChangeTimestamp > -1 && _now - this.lastChangeTimestamp >= 60 * Duration.millisecondsPerMinute) {
      this._updateTimer = Timer.periodic(Duration(minutes: 1), (timer) {
          final now = DateTime.now().millisecondsSinceEpoch;
          setState(() {
              this._timestampString = formatConversationTimestamp(
                this.lastChangeTimestamp,
                now
              );
          });

          if (now - this.lastChangeTimestamp >= 60 * Duration.millisecondsPerMinute) {
            this._updateTimer!.cancel();
            this._updateTimer = null;
          }
      });
    } else {
      this._updateTimer = null;
    }
  }

  @override
  void dispose() {
    if (this._updateTimer != null) {
      this._updateTimer!.cancel();
    }

    super.dispose();
  }
  
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
                // TODO: Make this consistent by moving this inside the AvatarWrapper widget
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
          visible: this.lastChangeTimestamp != TIMESTAMP_NEVER,
          child: Positioned(
            top: 8,
            right: 8,
            child: Text(
              this._timestampString
            )
          )
        ) 
      ]
    );
  }
}
