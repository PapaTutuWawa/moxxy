import 'package:flutter/material.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/widgets/chat/bottom.dart';

/// Used whenever the mime type either doesn't match any specific chat widget or we just
/// cannot determine the mime type.
class TextChatWidget extends StatelessWidget {

  const TextChatWidget(
    this.message,
    {
      this.topWidget,
      Key? key,
    }
  ) : super(key: key);
  final Message message;
  final Widget? topWidget;

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...topWidget != null ? [ topWidget! ] : [],
          Padding(
            padding: topWidget != null ? const EdgeInsets.only(left: 8) : EdgeInsets.zero,
            child: Text(
              message.body,
              style: const TextStyle(
                color: Colors.white,
                fontSize: fontsizeBody,
              ),
            ),
          ),
          Padding(
            padding: topWidget != null ? const EdgeInsets.only(left: 8, right: 8, bottom: 8) : EdgeInsets.zero,
            child: MessageBubbleBottom(message),
          )
        ],
      ),
    );
  }
}
