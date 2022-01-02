import "dart:async";

import "package:moxxyv2/models/message.dart";
import "package:moxxyv2/ui/constants.dart";
import "package:moxxyv2/helpers.dart";

import "package:flutter/material.dart";

class ChatBubble extends StatefulWidget {
  final Message message;
  final bool sentBySelf;
  // 
  final bool closerTogether;
  final bool between;
  final bool start;
  final bool end;
  final double maxWidth;

  ChatBubble({
      required this.message,
      required this.sentBySelf,
      required this.closerTogether,
      required this.between,
      required this.start,
      required this.end,
      required this.maxWidth,
      Key? key
  }) : super(key: key);

  @override
  _ChatBubbleState createState() => _ChatBubbleState(
      message: this.message,
      sentBySelf: this.sentBySelf,
      closerTogether: this.closerTogether,
      between: this.between,
      start: this.start,
      end: this.end,
      maxWidth: this.maxWidth
  );
}

class _ChatBubbleState extends State<ChatBubble> {
  final Message message;
  final bool sentBySelf;
  // 
  final bool closerTogether;
  final bool between;
  final bool start;
  final bool end;
  final double maxWidth;

  late String _timestampString;
  late Timer? _updateTimer;

  _ChatBubbleState({
      required this.message,
      required this.sentBySelf,
      required this.closerTogether,
      required this.between,
      required this.start,
      required this.end,
      required this.maxWidth
  }) {
    // Different name for now to prevent possible shadowing issues
    final _now = DateTime.now().millisecondsSinceEpoch;
    this._timestampString = formatMessageTimestamp(this.message.timestamp, _now);

    // Only start the timer if neccessary
    if (_now - this.message.timestamp <= 15 * Duration.millisecondsPerMinute) {
      print("Starting timer");
      this._updateTimer = Timer.periodic(Duration(minutes: 1), (timer) {
          this.setState(() {
              final now = DateTime.now().millisecondsSinceEpoch;
              this._timestampString = formatMessageTimestamp(this.message.timestamp, now);

              if (now - this.message.timestamp > 15 * Duration.millisecondsPerMinute) {
                print("Cancelling timer");
                this._updateTimer!.cancel();
              }
          });
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
    return Padding(
      padding: EdgeInsets.only(
        left: !this.sentBySelf ? 8.0 : 0.0, // Conditional
        right: this.sentBySelf ? 8.0 : 0.0,
        top: 1.0,
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
                      this.message.body,
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
                            this._timestampString,
                            style: TextStyle(
                              fontSize: FONTSIZE_SUBBODY,
                              // TODO: Maybe a bit too dark on received messages
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
