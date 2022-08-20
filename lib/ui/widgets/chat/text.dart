import 'package:dart_emoji/dart_emoji.dart';
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
    final fontsize = EmojiUtil.hasOnlyEmojis(
      message.body,
      ignoreWhitespace: true,
    ) ? fontsizeBodyOnlyEmojis : fontsizeBody;
    return IntrinsicWidth(child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...topWidget != null ? [ topWidget! ] : [],
          Padding(
            padding: topWidget != null ? const EdgeInsets.only(left: 8) : EdgeInsets.zero,
            child: Text(
              message.body,
              style: TextStyle(
                color: Colors.white,
                fontSize: fontsize,
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
