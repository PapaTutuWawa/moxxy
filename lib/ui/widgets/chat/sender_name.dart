import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxmpp/moxxmpp.dart';
import 'package:moxxmpp_color/moxxmpp_color.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/state/conversation.dart';

class SenderName extends StatelessWidget {
  const SenderName(
    this.senderJid,
    this.sent,
    this.isGroupchat, {
    this.showShadow = false,
    super.key,
  });

  /// Whether the message was sent by us or someone else.
  final bool sent;

  /// The JID of the sender.
  final JID senderJid;

  /// Whether the current chat is a groupchat (true) or not (false).
  final bool isGroupchat;

  /// Controls whether a shadow around the text is shown. Useful for images, where
  /// we cannot control the background behind the text.
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    final sender = switch (isGroupchat) {
      true => sent ? t.messages.you : senderJid.resource,
      false => sent
          ? t.messages.you
          : GetIt.I
              .get<ConversationCubit>()
              .state
              .conversation!
              .titleWithOptionalContact,
    };

    final colorInput = switch (isGroupchat) {
      // TODO(Unknown): Follow Modern XMPP's guidelines on consistent color generation here.
      true => senderJid.resource,
      false => senderJid.toBare().toString(),
    };
    final textColor =
        sent ? bubbleTextQuoteSenderColor : consistentColorSync(colorInput);
    return Text(
      sender,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        color: textColor,
        fontSize: 16,
        shadows: [
          if (showShadow)
            BoxShadow(
              blurRadius: 12,
              color: textColor,
            ),
        ],
      ),
      overflow: TextOverflow.ellipsis,
    );
  }
}
