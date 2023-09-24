import 'dart:async';
import 'dart:io';
import 'package:badges/badges.dart' as badges;
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/constants.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/shared/models/conversation.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/service/data.dart';
import 'package:moxxyv2/ui/widgets/avatar.dart';
import 'package:moxxyv2/ui/widgets/chat/shared/image.dart';
import 'package:moxxyv2/ui/widgets/chat/shared/video.dart';
import 'package:moxxyv2/ui/widgets/chat/typing.dart';
import 'package:moxxyv2/ui/widgets/contact_helper.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class AnimatedMaterialColor extends StatefulWidget {
  const AnimatedMaterialColor({
    required this.color,
    required this.child,
    super.key,
  });

  /// The color attribute of the [Material] widget.
  final Color color;

  /// The child widget of the [Material] widget.
  final Widget child;

  @override
  AnimatedMaterialColorState createState() => AnimatedMaterialColorState();
}

class AnimatedMaterialColorState extends State<AnimatedMaterialColor>
    with TickerProviderStateMixin {
  late final AnimationController _controller;
  late final ColorTween _tween;
  late final Animation<Color?> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _tween = ColorTween(
      begin: widget.color,
      end: widget.color,
    );

    _animation = _tween.animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(AnimatedMaterialColor oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.color != widget.color) {
      _tween
        ..begin = oldWidget.color
        ..end = widget.color;

      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, child) => Material(
        color: _animation.value,
        child: child,
      ),
      child: widget.child,
    );
  }
}

// TODO(Unknown): Make this widget less reliant on a [Conversation], so that we can use
//                it to build the icon entry in other pages, like the newconversation page.
class ConversationsListRow extends StatefulWidget {
  const ConversationsListRow(
    this.conversation,
    this.update, {
    required this.isSelected,
    this.showTimestamp = true,
    this.titleSuffixIcon,
    this.enableAvatarOnTap = false,
    this.avatarWidget,
    this.onPressed,
    super.key,
  });
  final Conversation conversation;
  final bool update; // Should a timer run to update the timestamp
  final IconData? titleSuffixIcon;
  final bool showTimestamp;
  final bool enableAvatarOnTap;
  final Widget? avatarWidget;

  /// Flag indicating whether the conversation row is selected (true) or not (false).
  final bool isSelected;

  /// Callback for when the row has been tapped.
  final VoidCallback? onPressed;

  @override
  ConversationsListRowState createState() => ConversationsListRowState();
}

class ConversationsListRowState extends State<ConversationsListRow> {
  late String _timestampString;
  late Timer? _updateTimer;

  @override
  void initState() {
    super.initState();

    final initNow = DateTime.now().millisecondsSinceEpoch;

    _timestampString = formatConversationTimestamp(
      widget.conversation.lastChangeTimestamp,
      initNow,
    );

    // NOTE: We could also check and run the timer hourly, but who has a messenger on the
    //       conversation screen open for hours on end?
    if (widget.update &&
        widget.conversation.lastChangeTimestamp > -1 &&
        initNow - widget.conversation.lastChangeTimestamp >=
            60 * Duration.millisecondsPerMinute) {
      _updateTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
        final now = DateTime.now().millisecondsSinceEpoch;
        setState(() {
          _timestampString = formatConversationTimestamp(
            widget.conversation.lastChangeTimestamp,
            now,
          );
        });

        if (now - widget.conversation.lastChangeTimestamp >=
            60 * Duration.millisecondsPerMinute) {
          _updateTimer!.cancel();
          _updateTimer = null;
        }
      });
    } else {
      _updateTimer = null;
    }
  }

  @override
  void dispose() {
    if (_updateTimer != null) {
      _updateTimer!.cancel();
    }

    super.dispose();
  }

  Widget _buildAvatar() {
    return RebuildOnContactIntegrationChange(
      builder: () {
        final avatar = CachingXMPPAvatar(
          radius: 35,
          jid: widget.conversation.jid,
          hash: widget.conversation.avatarHash,
          path: widget.conversation.avatarPathWithOptionalContact,
          hasContactId: widget.conversation.contactId != null,
          isGroupchat: widget.conversation.isGroupchat,
          altIcon: widget.conversation.type == ConversationType.note
              ? Icons.notes
              : null,
          shouldRequest: widget.conversation.type != ConversationType.note,
        );

        if (widget.enableAvatarOnTap &&
            widget.conversation.avatarPathWithOptionalContact != null &&
            widget.conversation.avatarPathWithOptionalContact!.isNotEmpty) {
          return InkWell(
            onTap: () => showDialog<void>(
              context: context,
              builder: (context) {
                return IgnorePointer(
                  child: Image.file(
                    File(widget.conversation.avatarPathWithOptionalContact!),
                  ),
                );
              },
            ),
            child: avatar,
          );
        }

        return avatar;
      },
    );
  }

  Widget _buildLastMessagePreview() {
    Widget? preview;
    if (widget.conversation.lastMessage!.stickerPackId != null) {
      if (widget.conversation.lastMessage!.fileMetadata!.path != null) {
        preview = SharedImageWidget(
          widget.conversation.lastMessage!.fileMetadata!.path!,
          borderRadius: 5,
          size: 30,
        );
      } else {
        preview = Icon(
          PhosphorIcons.regular.sticker,
          size: 30,
        );
      }
    } else if (widget.conversation.lastMessage!.fileMetadata!.mimeType!
        .startsWith('image/')) {
      if (widget.conversation.lastMessage!.fileMetadata!.path == null) {
        preview = const SizedBox();
      } else {
        preview = SharedImageWidget(
          widget.conversation.lastMessage!.fileMetadata!.path!,
          borderRadius: 5,
          size: 30,
        );
      }
    } else if (widget.conversation.lastMessage!.fileMetadata!.mimeType!
        .startsWith('video/')) {
      if (widget.conversation.lastMessage!.fileMetadata!.path == null) {
        preview = const SizedBox();
      } else {
        preview = SharedVideoWidget(
          widget.conversation.lastMessage!.fileMetadata!.path!,
          widget.conversation.jid,
          widget.conversation.lastMessage!.fileMetadata!.mimeType!,
          borderRadius: 5,
          size: 30,
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.only(right: 5),
      child: preview,
    );
  }

  Widget _buildLastMessageBody() {
    if (widget.conversation.isTyping) {
      return const TypingIndicatorWidget(Colors.black, Colors.white);
    }

    final lastMessage = widget.conversation.lastMessage;
    String body;
    if (lastMessage == null) {
      body = '';
    } else {
      if (lastMessage.isRetracted) {
        body = t.messages.retracted;
      } else if (lastMessage.isMedia) {
        // If the file is thumbnailable, we display a small preview on the left of the
        // body, so we don't need the emoji then.
        if (lastMessage.stickerPackId != null) {
          body = t.messages.sticker;
        } else if (lastMessage.isThumbnailable) {
          body = mimeTypeToName(lastMessage.fileMetadata!.mimeType);
        } else {
          body = mimeTypeToEmoji(lastMessage.fileMetadata!.mimeType);
        }
      } else {
        body = widget.conversation.lastMessage!.body;
      }
    }

    return Text(
      body,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _getLastMessageIcon(bool sentBySelf) {
    final lastMessage = widget.conversation.lastMessage;
    if (lastMessage == null) return const SizedBox();

    Widget? icon;
    if (sentBySelf) {
      if (lastMessage.displayed) {
        icon = Icon(
          Icons.done_all,
          color: Colors.blue.shade700,
        );
      } else if (lastMessage.received) {
        icon = const Icon(Icons.done_all);
      } else if (lastMessage.acked) {
        icon = const Icon(Icons.done);
      } else if (lastMessage.hasError) {
        icon = const Icon(
          Icons.info_outline,
          color: Colors.red,
        );
      }
    } else {
      if (lastMessage.isEdited) {
        icon = const Icon(Icons.edit);
      }
    }

    if (icon != null) {
      if (widget.conversation.unreadCounter > 0) {
        return Padding(
          padding: const EdgeInsets.only(right: 5),
          child: icon,
        );
      } else {
        return icon;
      }
    }

    return const SizedBox();
  }

  @override
  Widget build(BuildContext context) {
    final badgeText = widget.conversation.unreadCounter > 99
        ? '99+'
        : widget.conversation.unreadCounter.toString();
    final showTimestamp =
        widget.conversation.lastChangeTimestamp != timestampNever &&
            widget.showTimestamp;
    final sentBySelf = widget.conversation.lastMessage?.sender ==
        GetIt.I.get<UIDataService>().ownJid!;

    final showBadge = widget.conversation.unreadCounter > 0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radiusLargeSize),
        child: AnimatedMaterialColor(
          color: widget.isSelected ? Colors.blue : Colors.transparent,
          child: InkWell(
            onTap: widget.onPressed ?? () {},
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  _buildAvatar(),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              RebuildOnContactIntegrationChange(
                                builder: () => Text(
                                  widget.conversation.titleWithOptionalContact,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (widget.titleSuffixIcon != null)
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(horizontal: 6),
                                  child: Icon(
                                    widget.titleSuffixIcon,
                                    size: 17,
                                  ),
                                ),
                              if (showTimestamp) const Spacer(),
                              if (showTimestamp) Text(_timestampString),
                            ],
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (sentBySelf && !widget.conversation.isTyping)
                                Padding(
                                  padding: const EdgeInsets.only(
                                    right: 8,
                                  ),
                                  child: Text(
                                    '${t.messages.you}:',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              if ((widget.conversation.lastMessage
                                          ?.isThumbnailable ??
                                      false) &&
                                  !widget.conversation.isTyping)
                                Padding(
                                  padding: const EdgeInsets.only(right: 5),
                                  child: _buildLastMessagePreview(),
                                )
                              else
                                const SizedBox(height: 30),
                              Expanded(
                                child: _buildLastMessageBody(),
                              ),
                              _getLastMessageIcon(sentBySelf),
                              // Off-stage the badge if not visible to prevent the invisible
                              // badge taking up space.
                              Offstage(
                                offstage: !showBadge,
                                child: badges.Badge(
                                  badgeContent: Text(badgeText),
                                  showBadge: showBadge,
                                  badgeStyle: const badges.BadgeStyle(
                                    badgeColor: bubbleColorSent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
