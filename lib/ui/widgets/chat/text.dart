import "package:moxxyv2/ui/constants.dart";
import "package:moxxyv2/ui/widgets/chat/bottom.dart";

import "package:flutter/material.dart";

/// Used whenever the mime type either doesn't match any specific chat widget or we just
/// cannot determine the mime type.
class TextChatWidget extends StatelessWidget {
  final String timestamp;
  final String body;
  final bool received;
  final bool displayed;
  final Widget? topWidget;
  final bool enablePadding;

  const TextChatWidget({
      required this.body,
      required this.timestamp,
      required this.received,
      required this.displayed,
      this.enablePadding = true,
      this.topWidget,
      Key? key
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...(topWidget != null ? [ topWidget! ] : []),
          Padding(
            padding: enablePadding ? const EdgeInsets.only(left: 8.0) : const EdgeInsets.only(left: 0.0),
            child: Text(
              body,
              style: const TextStyle(
                color: Colors.white,
                fontSize: fontsizeBody
              ),
            )
          ),
          Padding(
            padding: enablePadding ? const EdgeInsets.all(8.0) : const EdgeInsets.all(0.0),
            child: MessageBubbleBottom(timestamp: timestamp, received: received, displayed: displayed)
          )
        ]
      )
    );
  }
}
