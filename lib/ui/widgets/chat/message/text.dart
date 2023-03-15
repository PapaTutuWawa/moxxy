import 'package:dart_emoji/dart_emoji.dart';
import 'package:flutter/material.dart';
import 'package:flutter_parsed_text/flutter_parsed_text.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/error_types.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/ui/widgets/chat/bottom.dart';

/// Used whenever the mime type either doesn't match any specific chat widget or we just
/// cannot determine the mime type.
class TextChatWidget extends StatelessWidget {
  const TextChatWidget(
    this.message,
    this.sent, {
    this.topWidget,
    super.key,
  });
  final Message message;
  final bool sent;
  final Widget? topWidget;

  String getMessageText() {
    if (message.hasError &&
        message.errorType! >= messageNotEncryptedForDevice &&
        message.errorType! <= messageInvalidAffixElements) {
      return errorToTranslatableString(message.errorType!);
    }

    if (message.isRetracted) {
      return t.messages.retracted;
    }

    return message.body;
  }

  @override
  Widget build(BuildContext context) {
    final fontsize = EmojiUtil.hasOnlyEmojis(
              message.body,
              ignoreWhitespace: true,
            ) &&
            !message.hasError &&
            !message.isRetracted
        ? fontsizeBodyOnlyEmojis
        : fontsizeBody;

    return IntrinsicWidth(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (topWidget != null) topWidget!,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ParsedText(
              text: getMessageText(),
              style: TextStyle(
                color: bubbleTextColor,
                fontSize: fontsize,
              ),
              parse: [
                MatchText(
                  // Taken from flutter_parsed_text's source code. Added ";" and "%" to
                  // valid URLs
                  pattern:
                      r'[(http(s)?):\/\/(www\.)?a-zA-Z0-9@:._\+-~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:_\+.~#?&\/\/=\;\%]*)',
                  style: const TextStyle(
                    decoration: TextDecoration.underline,
                  ),
                  onTap: handleUri,
                )
              ],
            ),
          ),
          Padding(
            padding: topWidget != null
                ? const EdgeInsets.only(left: 8, right: 8, bottom: 8)
                : EdgeInsets.zero,
            child: MessageBubbleBottom(
              message,
              message.conversationJid == '' ? true : sent,
            ),
          )
        ],
      ),
    );
  }
}
