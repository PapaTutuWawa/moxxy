import 'package:flutter/material.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/widgets/chat/quote/base.dart';
import 'package:moxxyv2/ui/widgets/chat/quote/helpers.dart';

class QuotedTextWidget extends StatelessWidget {
  const QuotedTextWidget(
    this.message,
    this.sent, {
      this.resetQuote,
      super.key,
    }
  );
  final Message message;
  final bool sent;
  final void Function()? resetQuote;
  
  @override
  Widget build(BuildContext context) {
    return QuoteBaseWidget(
      message,
      Text(
        message.body,
        style: TextStyle(
          color: getQuoteTextColor(context, resetQuote != null),
        ),
      ),
      sent,
      resetQuotedMessage: resetQuote,
    );
  }
}
