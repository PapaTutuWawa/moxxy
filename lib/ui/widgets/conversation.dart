import "dart:async";

import "package:moxxyv2/ui/constants.dart";
import "package:moxxyv2/ui/widgets/avatar.dart";
import "package:moxxyv2/ui/widgets/chat/typing.dart";
import "package:moxxyv2/shared/helpers.dart";
import "package:moxxyv2/shared/constants.dart";

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
  final bool typingIndicator;
  
  const ConversationsListRow(
    this.avatarUrl,
    this.name,
    this.lastMessageBody,
    this.unreadCount,
    this.maxTextWidth,
    this.lastChangeTimestamp,
    this.update, {
      this.typingIndicator = false,
      Key? key
    }
  ) : super(key: key);

  @override
  _ConversationsListRowState createState() => _ConversationsListRowState();
}

class _ConversationsListRowState extends State<ConversationsListRow> {
  late String _timestampString;
  late Timer? _updateTimer;

  @override
  void initState() {
    super.initState();

    final _now = DateTime.now().millisecondsSinceEpoch;

    _timestampString = formatConversationTimestamp(
      widget.lastChangeTimestamp,
      _now
    );

    // NOTE: We could also check and run the timer hourly, but who has a messenger on the
    //       conversation screen open for hours on end?
    if (widget.update && widget.lastChangeTimestamp > -1 && _now - widget.lastChangeTimestamp >= 60 * Duration.millisecondsPerMinute) {
      _updateTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
          final now = DateTime.now().millisecondsSinceEpoch;
          setState(() {
              _timestampString = formatConversationTimestamp(
                widget.lastChangeTimestamp,
                now
              );
          });

          if (now - widget.lastChangeTimestamp >= 60 * Duration.millisecondsPerMinute) {
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

  Widget _buildLastMessageBody() {
    if (widget.typingIndicator) {
      return const TypingIndicatorWidget(Colors.black, Colors.white);
    }

    return Text(
      widget.lastMessageBody,
      maxLines: 1,
      overflow: TextOverflow.ellipsis
    );
  }
  
  @override
  Widget build(BuildContext context) {
    String badgeText = widget.unreadCount > 99 ? "99+" : widget.unreadCount.toString();
    // TODO: Maybe turn this into an attribute of the widget to prevent calling this
    //       for every conversation
    final width = MediaQuery.of(context).size.width;

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        children: [
          AvatarWrapper(
            radius: 35.0,
            avatarUrl: widget.avatarUrl,
            altText: widget.name
          ),
          Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: width - 70.0 - 16.0 - 8.0,
                  child: Row(
                    children: [
                      Container(
                        constraints: BoxConstraints(
                          maxWidth: widget.maxTextWidth
                        ),
                        child: Text(
                          widget.name,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis
                        )
                      ),
                      const Spacer(),
                      Visibility(
                        visible: widget.lastChangeTimestamp != timestampNever,
                        child: Text(_timestampString)
                      )
                    ]
                  )
                ),
                SizedBox(
                  width: width - 70.0 - 16.0 - 8.0,
                  child: Row(
                    children: [
                      // TODO: Change color and font size
                      Container(
                        constraints: BoxConstraints(
                          maxWidth: widget.maxTextWidth
                        ),
                        // TODO: Colors
                        child: _buildLastMessageBody()
                      ),
                      const Spacer(),
                      Visibility(
                        visible: widget.unreadCount > 0,
                        child: Badge(
                          badgeContent: Text(badgeText),
                          badgeColor: bubbleColorSent
                        )
                      )
                    ]
                  )
                ),
              ]
            )
          ) 
        ]
      )
    );
  }
}
