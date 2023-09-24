import 'package:flutter/material.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/ui/constants.dart';

class SenderName extends StatelessWidget {
  const SenderName(
    this.senderJid,
    this.sent, {
    this.showShadow = false,
    super.key,
  });

  /// Whether the message was sent by us or someone else.
  final bool sent;

  /// The JID of the sender.
  final JID senderJid;

  /// Controls whether a shadow around the text is shown. Useful for images, where
  /// we cannot control the background behind the text.
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    return Text(
      sent ? t.messages.you : senderJid.resource,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        color: sent ? bubbleTextQuoteSenderColor : null,
        fontSize: 16,
        shadows: [
          if (showShadow) const BoxShadow(blurRadius: 12),
        ],
      ),
      overflow: TextOverflow.ellipsis,
    );
  }
}
