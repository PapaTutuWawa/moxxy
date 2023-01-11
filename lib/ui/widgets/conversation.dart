import 'dart:async';
import 'dart:io';
import 'package:badges/badges.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/constants.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/shared/models/conversation.dart';
import 'package:moxxyv2/shared/models/sticker.dart';
import 'package:moxxyv2/ui/bloc/preferences_bloc.dart';
import 'package:moxxyv2/ui/bloc/stickers_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/service/data.dart';
import 'package:moxxyv2/ui/widgets/avatar.dart';
import 'package:moxxyv2/ui/widgets/chat/shared/image.dart';
import 'package:moxxyv2/ui/widgets/chat/shared/video.dart';
import 'package:moxxyv2/ui/widgets/chat/typing.dart';
import 'package:moxxyv2/ui/widgets/contact_helper.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ConversationsListRow extends StatefulWidget {
  const ConversationsListRow(
    this.maxTextWidth,
    this.conversation,
    this.update, {
      this.showTimestamp = true,
      this.titleSuffixIcon,
      this.extra,
      this.enableAvatarOnTap = false,
      this.avatarWidget,
      this.extraWidgetWidth = 0,
      super.key,
    }
  );
  final Conversation conversation;
  final double maxTextWidth;
  final double extraWidgetWidth;
  final bool update; // Should a timer run to update the timestamp
  final IconData? titleSuffixIcon;
  final bool showTimestamp;
  final bool enableAvatarOnTap;
  final Widget? avatarWidget;
  final Widget? extra;

  @override
  ConversationsListRowState createState() => ConversationsListRowState();
}

class ConversationsListRowState extends State<ConversationsListRow> {
  late String _timestampString;
  late Timer? _updateTimer;

  @override
  void initState() {
    super.initState();

    final _now = DateTime.now().millisecondsSinceEpoch;

    _timestampString = formatConversationTimestamp(
      widget.conversation.lastChangeTimestamp,
      _now,
    );

    // NOTE: We could also check and run the timer hourly, but who has a messenger on the
    //       conversation screen open for hours on end?
    if (widget.update && widget.conversation.lastChangeTimestamp > -1 && _now - widget.conversation.lastChangeTimestamp >= 60 * Duration.millisecondsPerMinute) {
      _updateTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
        final now = DateTime.now().millisecondsSinceEpoch;
        setState(() {
          _timestampString = formatConversationTimestamp(
            widget.conversation.lastChangeTimestamp,
            now,
          );
        });

        if (now - widget.conversation.lastChangeTimestamp >= 60 * Duration.millisecondsPerMinute) {
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
        final avatar = AvatarWrapper(
          radius: 35,
          avatarUrl: widget.conversation.avatarPathWithOptionalContact,
          altText: widget.conversation.titleWithOptionalContact,
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

  Widget _buildLastMessagePreview(StickersState state) {
    Widget? preview;
    if (widget.conversation.lastMessage!.stickerPackId != null) {
      Sticker? sticker;
      if (widget.conversation.lastMessage!.stickerPackId != null &&
          widget.conversation.lastMessage!.stickerHashKey != null &&
          GetIt.I.get<PreferencesBloc>().state.enableStickers) {
        final stickerKey = StickerKey(
          widget.conversation.lastMessage!.stickerPackId!,
          widget.conversation.lastMessage!.stickerHashKey!,
        );

        sticker = state.stickerMap[stickerKey];
      }

      if (sticker != null) {
        preview = SharedImageWidget(
          sticker.path,
          borderRadius: 5,
          size: 30,
        );
      } else {
        preview = const Icon(
          PhosphorIcons.stickerBold,
          size: 30,
        );
      }
    } else if (widget.conversation.lastMessage!.mediaType!.startsWith('image/')) {
      if (widget.conversation.lastMessage!.mediaUrl == null) {
        preview = const SizedBox();
      } else {
        preview = SharedImageWidget(
          widget.conversation.lastMessage!.mediaUrl!,
          borderRadius: 5,
          size: 30,
        );
      }
    } else if (widget.conversation.lastMessage!.mediaType!.startsWith('video/')) {
      if (widget.conversation.lastMessage!.mediaUrl == null) {
        preview = const SizedBox();
      } else {
        preview = SharedVideoWidget(
          widget.conversation.lastMessage!.mediaUrl!,
          widget.conversation.jid,
          widget.conversation.lastMessage!.mediaType!,
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
          body = mimeTypeToName(lastMessage.mediaType);
        } else {
          body = mimeTypeToEmoji(lastMessage.mediaType);
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
    final badgeText = widget.conversation.unreadCounter > 99 ?
      '99+' :
      widget.conversation.unreadCounter.toString();
    final screenWidth = MediaQuery.of(context).size.width;
    final width = screenWidth - 24 - 70 - widget.extraWidgetWidth;
    final textWidth = screenWidth * 0.6;

    final showTimestamp = widget.conversation.lastChangeTimestamp != timestampNever && widget.showTimestamp;
    final sentBySelf = widget.conversation.lastMessage?.sender == GetIt.I.get<UIDataService>().ownJid!;

    final showBadge = widget.conversation.unreadCounter > 0 && !sentBySelf;

    return Padding(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          _buildAvatar(),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: LimitedBox(
              maxWidth: width,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
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
                      ...widget.titleSuffixIcon != null ?
                        [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Icon(
                              widget.titleSuffixIcon,
                              size: 17,
                            ),
                          ),
                        ] :
                        [],
                      Visibility(
                        visible: showTimestamp,
                        child: const Spacer(),
                      ),
                      Visibility(
                        visible: showTimestamp,
                        child: Text(_timestampString),
                      ),
                    ],
                  ),

                  Padding(
                    padding: const EdgeInsets.only(top: 5),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ...widget.conversation.lastMessage?.isThumbnailable == true && !widget.conversation.isTyping ? [
                          Padding(
                            padding: const EdgeInsets.only(right: 5),
                            child: BlocBuilder<StickersBloc, StickersState>(
                              buildWhen: (prev, next) => prev.stickerPacks.length != next.stickerPacks.length &&
                                widget.conversation.lastMessage?.stickerPackId != null,
                              builder: (_, state) => _buildLastMessagePreview(state),
                            ),
                          ),
                        ] : [
                          const SizedBox(height: 30),
                        ],
                        LimitedBox(
                          maxWidth: textWidth,
                          child: _buildLastMessageBody(),
                        ),
                        const Spacer(),

                        _getLastMessageIcon(sentBySelf),

                        Visibility(
                          visible: showBadge,
                          child: Badge(
                            badgeContent: Text(badgeText),
                            badgeColor: bubbleColorSent,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          ...widget.extra != null ? [
            const Spacer(),
              widget.extra!
            ] :
            [],
        ],
      ),
    );
  }
}
