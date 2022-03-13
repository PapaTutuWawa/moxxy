import "package:moxxyv2/ui/constants.dart";

import "package:flutter/material.dart";

class MessageBubbleBottom extends StatelessWidget {
  final String timestamp;
  final bool received;
  final bool displayed;
  final bool acked;

  const MessageBubbleBottom({
      required this.timestamp,
      required this.received,
      required this.displayed,
      required this.acked,
      Key? key
  }) : super(key: key);

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
        ...(acked && !received && !displayed ? [
            const Padding(
              padding: const EdgeInsets.only(left: 3.0),
              child: Icon(
                Icons.done,
                size: fontsizeSubbody * 2
              )
            )
          ] : []),
        ...(received && !displayed ? [
            const Padding(
              padding: EdgeInsets.only(left: 3.0),
              child: Icon(
                Icons.done_all,
                size: fontsizeSubbody * 2
              )
            )
          ] : []),
        ...(displayed ? [
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
