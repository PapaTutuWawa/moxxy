import 'package:flutter/material.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/ui/widgets/chat/quote/base.dart';
import 'package:moxxyv2/ui/widgets/chat/shared/file.dart';

class QuotedFileWidget extends StatelessWidget {
  const QuotedFileWidget(
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
      SharedFileWidget(
        message.mediaUrl!,
        size: 48,
        borderRadius: 8,
      ),
      message.filename!,
      sent,
      resetQuote: resetQuote,
    );
  }
}
