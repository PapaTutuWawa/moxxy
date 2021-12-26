import 'package:flutter/material.dart';
import "package:moxxyv2/ui/constants.dart";
import "package:moxxyv2/helpers.dart";

class ChatBubble extends StatelessWidget {
  final String messageContent;
  final int timestamp;
  final bool sentBySelf;
  // 
  final bool closerTogether;
  final bool between;
  final bool start;
  final bool end;
  final double maxWidth;

  ChatBubble({
      required this.messageContent,
      required this.timestamp,
      required this.sentBySelf,
      required this.closerTogether,
      required this.between,
      required this.start,
      required this.end,
      required this.maxWidth
  });

  @override
  Widget build(BuildContext context) {
    DateTime parsedTimestamp = DateTime.fromMillisecondsSinceEpoch(this.timestamp);
    String timestampString = padInt(parsedTimestamp.hour) + ":" + padInt(parsedTimestamp.minute);
    return Padding(
      padding: EdgeInsets.only(
        // TODO: Fix padding
        left: this.start ? 8.0 : 1.0, // Conditional
        right: 8.0,
        top: 5.0,
        bottom: this.closerTogether ? 1.0 : 8.0
      ),
      child: Row(
        mainAxisAlignment: this.sentBySelf ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: this.maxWidth
            ),
            decoration: BoxDecoration(
              color: this.sentBySelf ? BUBBLE_COLOR_SENT : BUBBLE_COLOR_RECEIVED,
              borderRadius: BorderRadius.only(
                topLeft: !this.sentBySelf && (this.between || this.end) && !(this.start && this.end) ? RADIUS_SMALL : RADIUS_LARGE,
                topRight: this.sentBySelf && (this.between || this.end) && !(this.start && this.end) ? RADIUS_SMALL : RADIUS_LARGE,
                bottomLeft: !this.sentBySelf && (this.between || this.start) && !(this.start && this.end) ? RADIUS_SMALL : RADIUS_LARGE,
                bottomRight: this.sentBySelf && (this.between || this.start) && !(this.start && this.end) ? RADIUS_SMALL : RADIUS_LARGE
              )
            ),
            child: Padding(
              padding: EdgeInsets.all(8.0),
              child: IntrinsicWidth(child: Column(
                  children: [
                    Text(
                      this.messageContent,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: FONTSIZE_BODY
                      )
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Padding(
                          padding: EdgeInsets.only(top: 3.0),
                          child: Text(
                            timestampString,
                            style: TextStyle(
                              fontSize: FONTSIZE_SUBBODY,
                              color: Colors.blueGrey[900]!
                            )
                          )
                        ) 
                      ]
                    )
                  ]
                )
              )
            )
          )
        ]
      )
    );
  }
}
