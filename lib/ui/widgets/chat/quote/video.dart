import 'package:flutter/material.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/ui/widgets/chat/quote/base.dart';
import 'package:moxxyv2/ui/widgets/chat/shared/video.dart';

class QuotedVideoWidget extends StatelessWidget {
  const QuotedVideoWidget(
    this.message,
    this.sent, {
    this.resetQuote,
    super.key,
  });
  final Message message;
  final bool sent;
  final void Function()? resetQuote;

  @override
  Widget build(BuildContext context) {
    return QuotedMediaBaseWidget(
      message,
      SharedVideoWidget(
        message.fileMetadata!.path!,
        message.conversationJid,
        message.fileMetadata!.mimeType!,
        size: 48,
        borderRadius: 8,
      ),
      t.messages.video,
      sent,
      resetQuote: resetQuote,
    );
  }
}
