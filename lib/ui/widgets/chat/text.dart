import 'package:dart_emoji/dart_emoji.dart';
import 'package:flutter/material.dart';
import 'package:flutter_parsed_text/flutter_parsed_text.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/redirects.dart';
import 'package:moxxyv2/ui/widgets/chat/bottom.dart';
import 'package:url_launcher/url_launcher.dart';

/// Used whenever the mime type either doesn't match any specific chat widget or we just
/// cannot determine the mime type.
class TextChatWidget extends StatelessWidget {

  const TextChatWidget(
    this.message,
    this.sent,
    {
      this.topWidget,
      Key? key,
    }
  ) : super(key: key);
  final Message message;
  final bool sent;
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
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ParsedText(
              text: message.body,
              style: TextStyle(
                color: const Color(0xf9ebffff),
                fontSize: fontsize,
              ),
              parse: [
                MatchText(
                  type: ParsedType.URL,
                  style: const TextStyle(
                    decoration: TextDecoration.underline,
                  ),
                  onTap: (url) async {
                    await launchUrl(
                      redirectUrl(Uri.parse(url)),
                      mode: LaunchMode.externalNonBrowserApplication,
                    );
                  },
                )
              ],
            ),
          ),
          Padding(
            padding: topWidget != null ? const EdgeInsets.only(left: 8, right: 8, bottom: 8) : EdgeInsets.zero,
            child: MessageBubbleBottom(message, sent),
          )
        ],
      ),
    );
  }
}
