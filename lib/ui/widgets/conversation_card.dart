import 'package:badges/badges.dart' as badges;
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/shared/models/conversation.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/ui/state/account.dart';
import 'package:moxxyv2/ui/widgets/avatar.dart';
import 'package:moxxyv2/ui/widgets/chat/shared/image.dart';
import 'package:moxxyv2/ui/widgets/chat/shared/video.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

IconData? _messageStateToIcon(Message msg) {
  if (msg.displayed) {
    return Icons.done_all;
  } else if (msg.received) {
    return Icons.done_all;
  } else if (msg.acked) {
    return Icons.done;
  }

  return null;
}

class _RowIcon extends StatelessWidget {
  const _RowIcon(
    this.icon, {
    this.color,
  });

  /// The icon to show.
  final IconData icon;

  /// The color to use. Defaults to the "outline" color.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: pxToLp(8)),
      child: Icon(
        icon,
        size: pxToLp(48),
        color: color ?? Theme.of(context).colorScheme.outline,
      ),
    );
  }
}

/// A widget that allows highlighting parts of some text.
class HighlightWord extends StatelessWidget {
  const HighlightWord({
    required this.text,
    required this.style,
    this.overflow = TextOverflow.ellipsis,
    this.word,
    super.key,
  });

  /// Overflow behaviour. Defaults to [TextOverflow.ellipsis].
  final TextOverflow overflow;

  /// The text to display.
  final String text;

  /// The word to highlight. If null or '', this widget is equivalent
  /// to [Text].
  final String? word;

  /// The base style to apply to the text.
  final TextStyle style;

  /// Compute a list of [TextSpan]'s that applies the app's
  /// primary color to parts of the occurences of [word] in [text].
  List<TextSpan> _highlightWord() {
    final buffer = List<TextSpan>.empty(growable: true);
    var textBuffer = text.toLowerCase();
    var originalBuffer = text;
    final searchWord = word!.toLowerCase();
    while (textBuffer.isNotEmpty) {
      final occurence = textBuffer.indexOf(searchWord);
      if (occurence == -1) {
        buffer.add(
          TextSpan(text: originalBuffer),
        );
        textBuffer = '';
      } else {
        buffer
          ..add(
            TextSpan(
              text: originalBuffer.substring(0, occurence),
            ),
          )
          ..add(
            TextSpan(
              text:
                  originalBuffer.substring(occurence, occurence + word!.length),
              style: const TextStyle(color: primaryColor),
            ),
          );
        textBuffer = textBuffer.substring(occurence + word!.length);
        originalBuffer = originalBuffer.substring(occurence + word!.length);
      }
    }

    return buffer;
  }

  @override
  Widget build(BuildContext context) {
    if ((word ?? '').isEmpty) {
      return Text(
        text,
        style: style,
        overflow: TextOverflow.ellipsis,
      );
    }

    return RichText(
      text: TextSpan(
        style: style,
        children: _highlightWord(),
      ),
      overflow: overflow,
    );
  }
}

// A replacement widget for the "legacy" Conversation widget
class ConversationCard extends StatelessWidget {
  const ConversationCard({
    required this.conversation,
    required this.onTap,
    this.highlightWord,
    super.key,
  });

  /// The conversation to display.
  final Conversation conversation;

  /// An optional word to highlight.
  final String? highlightWord;

  /// Callback for when the conversation card has been tapped.
  final void Function() onTap;

  Widget _buildLastMessagePreview() {
    Widget? preview;
    if (conversation.lastMessage!.stickerPackId != null) {
      if (conversation.lastMessage!.fileMetadata!.path != null) {
        preview = SharedImageWidget(
          conversation.lastMessage!.fileMetadata!.path!,
          borderRadius: 5,
          size: 20,
        );
      } else {
        preview = Icon(
          PhosphorIcons.regular.sticker,
          size: 20,
        );
      }
    } else if (conversation.lastMessage!.fileMetadata!.mimeType!
        .startsWith('image/')) {
      if (conversation.lastMessage!.fileMetadata!.path == null) {
        preview = const SizedBox();
      } else {
        preview = SharedImageWidget(
          conversation.lastMessage!.fileMetadata!.path!,
          borderRadius: 5,
          size: 20,
        );
      }
    } else if (conversation.lastMessage!.fileMetadata!.mimeType!
        .startsWith('video/')) {
      if (conversation.lastMessage!.fileMetadata!.path == null) {
        preview = const SizedBox();
      } else {
        preview = SharedVideoWidget(
          conversation.lastMessage!.fileMetadata!.path!,
          conversation.jid,
          conversation.lastMessage!.fileMetadata!.mimeType!,
          borderRadius: 5,
          size: 20,
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: preview,
    );
  }

  /// Render the "message" line under the conversation title, if we have a last
  /// message we can display.
  Widget _renderLastMessage(BuildContext context, bool sentBySelf) {
    if (conversation.lastMessage == null) {
      return const SizedBox();
    }

    final message = conversation.lastMessage!;
    String body;
    if (message.isRetracted) {
      body = t.messages.retracted;
    } else if (message.isMedia) {
      // If the file is thumbnailable, we display a small preview on the left of the
      // body, so we don't need the emoji then.
      if (message.stickerPackId != null) {
        body = t.messages.sticker;
      } else if (message.isThumbnailable) {
        body = mimeTypeToName(message.fileMetadata!.mimeType);
      } else {
        body = mimeTypeToEmoji(message.fileMetadata!.mimeType);
      }
    } else {
      body = message.body;
    }

    final messageStateIcon = _messageStateToIcon(message);
    return Row(
      children: [
        if (message.hasError)
          _RowIcon(
            Icons.error_outline,
            color: Theme.of(context).colorScheme.error,
          ),

        // With read markers and an error it will get too crowded
        if (!conversation.isGroupchat &&
            sentBySelf &&
            !message.hasError &&
            messageStateIcon != null)
          _RowIcon(
            messageStateIcon,
            color: message.displayed
                ? Theme.of(context).colorScheme.primary
                : null,
          ),
        // TODO: Handle sender name in groupchats
        if (sentBySelf)
          Text(
            '${t.messages.you}: ',
            style: TextStyle(
              fontSize: ptToFontSize(32),
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),

        if (message.isMedia) _buildLastMessagePreview(),

        HighlightWord(
          text: body,
          word: highlightWord,
          style: TextStyle(
            fontSize: ptToFontSize(32),
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final sentBySelf = conversation.lastMessage?.sender ==
        GetIt.I.get<AccountCubit>().state.account.jid;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: pxToLp(192),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: pxToLp(48),
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: SquircleCachingXMPPAvatar(
                    jid: conversation.jid,
                    size: pxToLp(144),
                    // TODO: Constant
                    borderRadius: pxToLp(144 ~/ 4),
                    hasContactId: conversation.contactId != null,
                    isGroupchat: conversation.isGroupchat,
                    path: conversation.avatarPath,
                    hash: conversation.avatarHash,
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            if (conversation.favourite)
                              const _RowIcon(Icons.star_outline),

                            // TODO: Determine if its a public groupchat
                            if (conversation.isGroupchat)
                              const _RowIcon(Icons.public),

                            if (conversation.muted)
                              const _RowIcon(Icons.notifications_off),

                            Expanded(
                              child: HighlightWord(
                                text: conversation.titleWithOptionalContact,
                                word: highlightWord,
                                style: TextStyle(
                                  fontSize: ptToFontSize(32),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Offstage(
                              offstage: !conversation.hasUnreads,
                              child: Padding(
                                padding: EdgeInsets.only(
                                  left: pxToLp(12),
                                  right: pxToLp(24),
                                ),
                                child: badges.Badge(
                                  badgeStyle: badges.BadgeStyle(
                                    badgeColor:
                                        Theme.of(context).colorScheme.primary,
                                    padding: EdgeInsets.all(
                                      pxToLp(16),
                                    ),
                                  ),
                                  badgeContent: Text(
                                    conversation.unreadsString,
                                    style: TextStyle(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimary,
                                      fontSize: ptToFontSize(24),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            Text(
                              formatConversationTimestamp(
                                conversation.lastChangeTimestamp,
                                DateTime.now().millisecondsSinceEpoch,
                              ),
                              style: TextStyle(
                                fontSize: ptToFontSize(24),
                                color: conversation.hasUnreads
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).colorScheme.outline,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: _renderLastMessage(context, sentBySelf),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
