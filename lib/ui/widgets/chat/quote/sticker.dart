import 'package:flutter/material.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/ui/widgets/chat/quote/base.dart';
import 'package:moxxyv2/ui/widgets/chat/shared/image.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class QuotedStickerWidget extends StatelessWidget {
  const QuotedStickerWidget(
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
    if (message.fileMetadata!.path != null) {
      return QuotedMediaBaseWidget(
        message,
        SharedImageWidget(
          message.fileMetadata!.path!,
          size: 48,
          borderRadius: 8,
        ),
        message.body,
        sent,
        resetQuote: resetQuote,
      );
    } else {
      return QuoteBaseWidget(
        message,
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(
                PhosphorIcons.stickerBold,
              ),
            ),
            Text(
              message.body,
            ),
          ],
        ),
        sent,
        resetQuotedMessage: resetQuote,
      );
    }
  }
}
