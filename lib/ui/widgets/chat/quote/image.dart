import 'package:flutter/material.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/ui/widgets/chat/quote/base.dart';
import 'package:moxxyv2/ui/widgets/chat/shared/image.dart';

class QuotedImageWidget extends StatelessWidget {
  const QuotedImageWidget(
    this.message,
    this.sent,
    this.topLeftRadius,
    this.topRightRadius, {
    this.resetQuote,
    super.key,
  });
  final Message message;
  final bool sent;

  /// Top corner roundings.
  final double topLeftRadius;
  final double topRightRadius;

  final void Function()? resetQuote;

  @override
  Widget build(BuildContext context) {
    return QuotedMediaBaseWidget(
      message,
      SharedImageWidget(
        message.fileMetadata!.path!,
        size: 48,
        borderRadius: 8,
      ),
      t.messages.image,
      sent,
      topLeftRadius,
      topRightRadius,
      resetQuote: resetQuote,
    );
  }
}
