import 'package:flutter/material.dart';
import "package:moxxyv2/ui/constants.dart";

String padInt(int i) {
  if (i < 9) {
    return "0" + i.toString();
  }

  return i.toString();
}

class ChatBubble extends StatelessWidget {
  final String messageContent;
  final int timestamp;
  final bool sentBySelf;
  // 
  final bool closerTogether;
  final bool between;
  final bool start;
  final bool end;

  ChatBubble({
      required this.messageContent,
      required this.timestamp,
      required this.sentBySelf,
      required this.closerTogether,
      required this.between,
      required this.start,
      required this.end
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
              // TODO: Fix overflow
              child: IntrinsicWidth(child: Column(
                  children: [
                    Text(
                      this.messageContent,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 17
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
                              fontSize: 10,
                              color: Colors.grey
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
