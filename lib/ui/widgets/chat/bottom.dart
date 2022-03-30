import "package:moxxyv2/ui/constants.dart";
import "package:moxxyv2/shared/models/message.dart";

import "package:flutter/material.dart";

class MessageBubbleBottom extends StatelessWidget {
  final String timestamp;
  final Message message;

  const MessageBubbleBottom(
    this.message,
    {
      required this.timestamp,
      Key? key
    }
  ) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 3.0),
          child: Text(
            timestamp,
            style: const TextStyle(
              fontSize: fontsizeSubbody,
              color: Color(0xffddfdfd)
            )
          )
        ),
        ...(message.sent && message.acked && !message.received && !message.displayed ? [
            const Padding(
              padding: EdgeInsets.only(left: 3.0),
              child: Icon(
                Icons.done,
                size: fontsizeSubbody * 2
              )
            )
          ] : []),
        ...(message.sent && message.received && !message.displayed ? [
            const Padding(
              padding: EdgeInsets.only(left: 3.0),
              child: Icon(
                Icons.done_all,
                size: fontsizeSubbody * 2
              )
            )
          ] : []),
        ...(message.sent && message.displayed ? [
            Padding(
              padding: const EdgeInsets.only(left: 3.0),
              child: Icon(
                Icons.done_all,
                size: fontsizeSubbody * 2,
                color: Colors.blue.shade700
              )
            )
          ] : [])
      ]
    );
  }
}
