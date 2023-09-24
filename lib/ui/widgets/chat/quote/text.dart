import 'package:flutter/material.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/ui/widgets/chat/quote/base.dart';
import 'package:moxxyv2/ui/widgets/chat/quote/helpers.dart';
import 'package:moxxyv2/ui/widgets/chat/sender_name.dart';

/// A widget that renders a quoted text message.
class QuotedTextWidget extends StatelessWidget {
  const QuotedTextWidget(
    this.message,
    this.sent,
    this.isGroupchat,
    this.topLeftRadius,
    this.topRightRadius, {
    this.resetQuote,
    super.key,
  });

  /// The quoted text message to render.
  final Message message;

  /// Flag indicating whether the message was sent by us or not.
  final bool sent;

  /// The top corner roundings
  final double topLeftRadius;
  final double topRightRadius;

  /// Optional function to reset the quote display.
  final void Function()? resetQuote;

  /// Whether the message was received inside a groupchat context (true) or not (false).
  final bool isGroupchat;

  @override
  Widget build(BuildContext context) {
    return QuoteBaseWidget(
      message,
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SenderName(
            message.senderJid,
            sent,
            isGroupchat,
          ),
          Text(
            message.body,
            style: TextStyle(
              color: getQuoteTextColor(context, resetQuote != null),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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
