import "package:moxxyv2/shared/models/message.dart";
import "package:moxxyv2/ui/constants.dart";
import "package:moxxyv2/ui/widgets/chat/bottom.dart";

import "package:flutter/material.dart";

/// Used whenever the mime type either doesn't match any specific chat widget or we just
/// cannot determine the mime type.
class TextChatWidget extends StatelessWidget {
  final Message message;
  final Widget? topWidget;
  final bool enablePadding;

  const TextChatWidget(
    this.message,
    {
      this.enablePadding = true,
      this.topWidget,
      Key? key
    }
  ) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...(topWidget != null ? [ topWidget! ] : []),
          Padding(
            padding: enablePadding ? const EdgeInsets.only(left: 8.0) : const EdgeInsets.only(left: 0.0),
            child: Text(
              message.body,
              style: const TextStyle(
                color: Colors.white,
                fontSize: fontsizeBody
              ),
            )
          ),
          Padding(
            padding: enablePadding ? const EdgeInsets.all(8.0) : const EdgeInsets.all(0.0),
            child: MessageBubbleBottom(message)
          )
        ]
      )
    );
  }
}
