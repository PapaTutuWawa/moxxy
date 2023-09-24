import 'package:flutter/material.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/ui/widgets/chat/quote/base.dart';
import 'package:moxxyv2/ui/widgets/chat/shared/audio.dart';

class QuotedAudioWidget extends StatelessWidget {
  const QuotedAudioWidget(
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

  /// Whether the message was sent/received in a groupchat context (true) or not (false).
  final bool isGroupchat;

  /// Top corner roundings.
  final double topLeftRadius;
  final double topRightRadius;

  final void Function()? resetQuote;

  @override
  Widget build(BuildContext context) {
    return QuotedMediaBaseWidget(
      message,
      SharedAudioWidget(
        message.fileMetadata!.path!,
        size: 48,
        borderRadius: 8,
      ),
      // TODO(Unknown): Include the audio messages duration here
      t.messages.audio,
      sent,
      isGroupchat,
      topLeftRadius,
      topRightRadius,
      resetQuote: resetQuote,
    );
  }
}
