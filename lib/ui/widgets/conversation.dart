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
  
  const ConversationsListRow(this.avatarUrl, this.name, this.lastMessageBody, this.unreadCount, this.maxTextWidth, this.lastChangeTimestamp, this.update, { Key? key }) : super(key: key);

  @override
  // ignore: no_logic_in_create_state
  _ConversationsListRowState createState() => _ConversationsListRowState(
    avatarUrl,
    name,
    lastMessageBody,
    unreadCount,
    maxTextWidth,
    lastChangeTimestamp,
    update
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

    _timestampString = formatConversationTimestamp(
      lastChangeTimestamp,
      _now
    );

    // NOTE: We could also check and run the timer hourly, but who has a messenger on the
    //       conversation screen open for hours on end?
    if (update && lastChangeTimestamp > -1 && _now - lastChangeTimestamp >= 60 * Duration.millisecondsPerMinute) {
      _updateTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
          final now = DateTime.now().millisecondsSinceEpoch;
          setState(() {
              _timestampString = formatConversationTimestamp(
                lastChangeTimestamp,
                now
              );
          });

          if (now - lastChangeTimestamp >= 60 * Duration.millisecondsPerMinute) {
            _updateTimer!.cancel();
            _updateTimer = null;
          }
      });
    } else {
      _updateTimer = null;
    }
  }

  @override
  void dispose() {
    if (_updateTimer != null) {
      _updateTimer!.cancel();
    }

    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    String badgeText = unreadCount > 99 ? "99+" : unreadCount.toString();

    return Stack(
      children: [
        Row(
          children: [
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: AvatarWrapper(
                radius: 35.0,
                avatarUrl: avatarUrl,
                // TODO: Make this consistent by moving this inside the AvatarWrapper widget
                alt: Text(name[0] + name[1])
              )
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: maxTextWidth
                    ),
                    child: Text(
                      name,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis
                    )
                  ),
                  // TODO: Change color and font size
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: maxTextWidth
                    ),

                    child: Text(
                      lastMessageBody,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis
                    )
                  )
                ]
              )
            ),
            const Spacer(),
            Visibility(
              visible: unreadCount > 0,
              child: Padding(
                padding: const EdgeInsetsDirectional.only(end: 8.0),
                child: Badge(
                  badgeContent: Text(badgeText),
                  badgeColor: bubbleColorSent
                )
              )
            )
          ]
        ),
        Visibility(
          visible: lastChangeTimestamp != timestampNever,
          child: Positioned(
            top: 8,
            right: 8,
            child: Text(
              _timestampString
            )
          )
        ) 
      ]
    );
  }
}
