import 'package:dart_emoji/dart_emoji.dart';
import 'package:flutter/material.dart';
import 'package:flutter_parsed_text/flutter_parsed_text.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/ui/widgets/chat/bottom.dart';
import 'package:moxxyv2/ui/widgets/chat/sender_name.dart';

/// Used whenever the mime type either doesn't match any specific chat widget or we just
/// cannot determine the mime type.
class TextChatWidget extends StatelessWidget {
  const TextChatWidget(
    this.message,
    this.sent,
    this.isGroupchat, {
    this.topWidget,
    super.key,
  });
  final Message message;
  final bool sent;
  final bool isGroupchat;
  final Widget? topWidget;

  String getMessageText() {
    if (message.isOmemoError) {
      return message.errorType!.translatableString;
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
          if (isGroupchat)
            Padding(
              padding: const EdgeInsets.only(
                left: 8,
                right: 8,
                bottom: 8,
              ),
              child: SenderName(
                message.senderJid,
                sent,
              ),
            ),
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
                // NOTE: We use [renderWidget] here because otherwise, flutter_parsed_text will
                //       use [TextSpan]s with a [GestureRecognizer]. This interferes with the
                //       surrounding [GestureDetector] that we use for long-press interactions.
                // Match quotes
                MatchText(
                  pattern: '> .*',
                  renderWidget: ({
                    required String pattern,
                    required String text,
                  }) {
                    return DecoratedBox(
                      decoration: const BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: Colors.grey,
                            width: textMessageQuoteBarWidth,
                          ),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: 2 * textMessageQuoteBarWidth,
                        ),
                        // TODO(Unknown): Somehow, we should also parse a possible link here
                        child: Text(
                          // Remove the leading "> "
                          text.substring(2),
                          style: const TextStyle(
                            color: bubbleTextQuoteColor,
                          ),
                        ),
                      ),
                    );
                  },
                ),
                // Match URLs
                MatchText(
                  // Taken from flutter_parsed_text's source code. Added ";" and "%" to
                  // valid URLs
                  pattern:
                      r'[(http(s)?):\/\/(www\.)?a-zA-Z0-9@:._\+-~#=]{2,256}\.[a-z]{2,6}\b([-a-zA-Z0-9@:_\+.~#?&\/\/=\;\%]*)',
                  onTap: handleUri,
                  renderWidget: ({
                    required String pattern,
                    required String text,
                  }) {
                    return Text(
                      text,
                      style: TextStyle(
                        fontSize: fontsize,
                        color: bubbleTextColor,
                        decoration: TextDecoration.underline,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: topWidget != null
                ? const EdgeInsets.only(left: 8, right: 8, bottom: 8)
                : EdgeInsets.zero,
            child: MessageBubbleBottom(
              message,
              sent,
            ),
          ),
        ],
      ),
    );
  }
}
