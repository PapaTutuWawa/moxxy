import 'package:dart_emoji/dart_emoji.dart';
import 'package:flutter/material.dart';
import 'package:flutter_parsed_text/flutter_parsed_text.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/error_types.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/redirects.dart';
import 'package:moxxyv2/ui/widgets/chat/bottom.dart';
import 'package:url_launcher/url_launcher.dart';

String errorTypeToText(int errorType) {
  switch (errorType) {
    case messageNotEncryptedForDevice: return 'Message not encrypted for device';
    case messageInvalidHMAC: return 'Could not decrypt message';
    case messageNoDecryptionKey: return 'No decryption key available';
    case messageInvalidAffixElements: return 'Invalid encrypted message';
    case messageInvalidNumber: return 'lol';
    default: return '';
  }
}

/// Used whenever the mime type either doesn't match any specific chat widget or we just
/// cannot determine the mime type.
class TextChatWidget extends StatelessWidget {
  const TextChatWidget(
    this.message,
    this.sent,
    {
      this.topWidget,
      super.key,
    }
  );
  final Message message;
  final bool sent;
  final Widget? topWidget;

  String getMessageText() {
    if (message.isError()) {
      return errorTypeToText(message.errorType!);
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
    ) && !message.isError() ?
      fontsizeBodyOnlyEmojis :
      fontsizeBody;

    return IntrinsicWidth(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ...topWidget != null ? [ topWidget! ] : [],
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ParsedText(
              text: getMessageText(),
              style: TextStyle(
                color: const Color(0xffffffff),
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
            padding: topWidget != null ?
              const EdgeInsets.only(left: 8, right: 8, bottom: 8) :
              EdgeInsets.zero,
            child: MessageBubbleBottom(message, sent),
          )
        ],
      ),
    );
  }
}
