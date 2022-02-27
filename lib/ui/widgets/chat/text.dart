import "package:moxxyv2/ui/constants.dart";
import "package:moxxyv2/ui/widgets/chat/bottom.dart";

import "package:flutter/material.dart";

/// Used whenever the mime type either doesn't match any specific chat widget or we just
/// cannot determine the mime type.
class TextChatWidget extends StatelessWidget {
  final String timestamp;
  final String body;

  const TextChatWidget({ required this.body, required this.timestamp, Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(child: Column(
        children: [
          Text(
            body,
            style: const TextStyle(
              color: Colors.white,
              fontSize: fontsizeBody
            )
          ),
          MessageBubbleBottom(timestamp: timestamp)
        ]
      )
    );
  }
}
