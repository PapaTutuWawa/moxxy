import 'package:flutter/material.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/ui/widgets/chat/quote/base.dart';
import 'package:moxxyv2/ui/widgets/chat/quote/helpers.dart';

/// A widget that renders a quoted text message.
class QuotedTextWidget extends StatelessWidget {
  const QuotedTextWidget(
    this.message,
    this.sent, {
      this.resetQuote,
      super.key,
    }
  );

  /// The quoted text message to render.
  final Message message;

  /// Flag indicating whether the message was sent by us or not.
  final bool sent;

  /// Optional function to reset the quote display.
  final void Function()? resetQuote;
 
  @override
  Widget build(BuildContext context) {
    return QuoteBaseWidget(
      message,
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          QuoteSenderText(
            sender: message.sender,
            resetQuoteNotNull: resetQuote != null,
            sent: sent,
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
      resetQuotedMessage: resetQuote,
    );
  }
}
