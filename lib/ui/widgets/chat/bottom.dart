import "package:moxxyv2/ui/constants.dart";

import "package:flutter/material.dart";

class MessageBubbleBottom extends StatelessWidget {
  final String timestamp;

  const MessageBubbleBottom({ required this.timestamp, Key? key }) : super(key: key);

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
              color: Color(0xffbdbdbd)
            )
          )
        ) 
      ]
    );
  }
}
