import 'package:flutter/material.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/ui/widgets/chat/quote/base.dart';
import 'package:moxxyv2/ui/widgets/chat/shared/image.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class QuotedStickerWidget extends StatelessWidget {
  const QuotedStickerWidget(
    this.message,
    this.sent,
    this.isGroupchat,
    this.topLeftRadius,
    this.topRightRadius, {
    this.resetQuote,
    super.key,
  });
  final Message message;
  final bool sent;
  final void Function()? resetQuote;

  /// Whether the message was sent/received in a groupchat context (true) or not (false).
  final bool isGroupchat;

  /// The Radii of upper corners
  final double topLeftRadius;
  final double topRightRadius;

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
        t.messages.sticker,
        sent,
        isGroupchat,
        topLeftRadius,
        topRightRadius,
        resetQuote: resetQuote,
      );
    } else {
      return QuoteBaseWidget(
        message,
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(
                PhosphorIconsRegular.sticker,
              ),
            ),
            Text(
              message.body,
            ),
          ],
        ),
        sent,
        topLeftRadius,
        topRightRadius,
        resetQuotedMessage: resetQuote,
      );
    }
  }
}
