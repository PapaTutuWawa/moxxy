import 'package:flutter/material.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/ui/widgets/chat/quote/base.dart';
import 'package:moxxyv2/ui/widgets/chat/quote/helpers.dart';

class QuotedMediaBaseWidget extends StatelessWidget {
  const QuotedMediaBaseWidget(
    this.message,
    this.child,
    this.text,
    this.sent, {
    this.resetQuote,
    super.key,
  });
  final Message message;
  final Widget child;
  final String text;
  final bool sent;
  final void Function()? resetQuote;

  @override
  Widget build(BuildContext context) {
    return QuoteBaseWidget(
      message,
      Row(
        children: [
          child,
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                QuoteSenderText(
                  sender: message.sender,
                  resetQuoteNotNull: resetQuote != null,
                  sent: sent,
                ),
                Text(
                  text,
                  style: TextStyle(
                    color: getQuoteTextColor(context, resetQuote != null),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      sent,
      resetQuotedMessage: resetQuote,
    );
  }
}
