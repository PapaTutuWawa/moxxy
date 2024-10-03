// TODO(Unknown): The timestamp may be too light
// TODO(Unknown): The timestamp is too small
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/widgets/chat/message.dart';
import 'package:moxxyv2/ui/widgets/chat/reactions/preview.dart';
import 'package:swipeable_tile/swipeable_tile.dart';
import 'package:visibility_detector/visibility_detector.dart';

class RawChatBubble extends StatelessWidget {
  const RawChatBubble(
    this.message,
    this.maxWidth,
    this.sentBySelf,
    this.chatEncrypted,
    this.start,
    this.between,
    this.end,
    this.isGroupchat, {
    super.key,
  });
  final Message message;
  final double maxWidth;
  final bool sentBySelf;
  final bool chatEncrypted;
  final bool between;
  final bool end;
  final bool start;
  final bool isGroupchat;

  static BorderRadius getBorderRadius(
    bool sentBySelf,
    bool start,
    bool between,
    bool end,
  ) {
    return BorderRadius.only(
      topLeft: !sentBySelf && (between || end) && !(start && end)
          ? radiusSmall
          : radiusLarge,
      topRight: sentBySelf && (between || end) && !(start && end)
          ? radiusSmall
          : radiusLarge,
      bottomLeft: !sentBySelf && (between || start) && !(start && end)
          ? radiusSmall
          : radiusLarge,
      bottomRight: sentBySelf && (between || start) && !(start && end)
          ? radiusSmall
          : radiusLarge,
    );
  }

  /// Specified when the message bubble should not have color
  bool _shouldNotColorBubble() {
    var isInlinedWidget = false;
    if (message.isMedia) {
      isInlinedWidget =
          message.fileMetadata!.mimeType?.startsWith('image/') ?? false;
    }

    // Check if it is a pseudo message
    if (message.isPseudoMessage) {
      return true;
    }

    // Check if we can display a file upload notification
    // TODO(Unknown): Maybe support other thumbnail types
    final canDisplayFileUploadNotification =
        message.fileMetadata?.thumbnailType == 'blurhash' &&
            message.fileMetadata?.thumbnailData != null;
    if (message.isFileUploadNotification && !canDisplayFileUploadNotification) {
      return false;
    }

    // Check if it is an embedded file
    if (message.isMedia &&
        message.fileMetadata!.path != null &&
        isInlinedWidget) {
      return true;
    }

    // Stickers are also not colored
    return message.stickerPackId != null;
  }

  Color _getBubbleColor(BuildContext context) {
    if (_shouldNotColorBubble()) return Colors.transparent;

    // Color the bubble red if it should be encrypted but is not.
    if (chatEncrypted && !message.encrypted) {
      return bubbleColorUnencrypted;
    }

    if (message.isRetracted) {
      if (sentBySelf) {
        return const Color(0xff614d91);
      } else {
        return const Color(0xff585858);
      }
    }

    if (sentBySelf) {
      return bubbleColorSent;
    } else {
      return bubbleColorReceived;
    }
  }

  @override
  Widget build(BuildContext context) {
    final borderRadius = getBorderRadius(sentBySelf, start, between, end);
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maxWidth,
      ),
      child: Material(
        color: _getBubbleColor(context),
        borderRadius: borderRadius,
        child: Padding(
          // NOTE: Images don't work well with padding here
          padding: message.isMedia || message.quotes != null
              ? EdgeInsets.zero
              : const EdgeInsets.all(8),
          child: buildMessageWidget(
            message,
            isGroupchat,
            maxWidth,
            borderRadius,
            sentBySelf,
            borderRadius.topLeft.x,
            borderRadius.topRight.x,
          ),
        ),
      ),
    );
  }
}

class ChatBubble extends StatefulWidget {
  const ChatBubble({
    required this.message,
    required this.sentBySelf,
    required this.maxWidth,
    required this.onSwipedCallback,
    required this.bubble,
    this.onLongPressed,
    this.visibilityCallback,
    super.key,
  });

  /// The actual message to render.
  final Message message;

  /// Flag indicating whether the message was sent by us or not.
  final bool sentBySelf;

  /// For rendering the corners
  final double maxWidth;

  /// For acting on swiping
  final void Function(Message) onSwipedCallback;

  /// For acting on long-pressing the message
  final GestureLongPressStartCallback? onLongPressed;

  /// The actual message bubble
  final RawChatBubble bubble;

  /// An optional callback for when the visiblity of the message bubble
  /// changed.
  final VisibilityChangedCallback? visibilityCallback;

  @override
  ChatBubbleState createState() => ChatBubbleState();
}

class ChatBubbleState extends State<ChatBubble>
    with AutomaticKeepAliveClientMixin<ChatBubble> {
  @override
  bool get wantKeepAlive => true;

  SwipeDirection _getSwipeDirection() {
    // Should the message be quotable?
    if (!widget.message.isQuotable) {
      return SwipeDirection.none;
    }

    return widget.sentBySelf
        ? SwipeDirection.endToStart
        : SwipeDirection.startToEnd;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return VisibilityDetector(
      key: ValueKey('message-visibility;${widget.message}'),
      onVisibilityChanged: widget.visibilityCallback?.call,
      child: SwipeableTile.swipeToTrigger(
        direction: _getSwipeDirection(),
        swipeThreshold: 0.2,
        onSwiped: (_) => widget.onSwipedCallback(widget.message),
        backgroundBuilder: (_, direction, progress) {
          // NOTE: Taken from https://github.com/watery-desert/swipeable_tile/blob/main/example/lib/main.dart#L240
          //       and modified.
          var vibrated = false;
          return AnimatedBuilder(
            animation: progress,
            builder: (_, __) {
              if (progress.value > 0.9999 && !vibrated) {
                HapticFeedback.lightImpact();
                vibrated = true;
              } else if (progress.value < 0.9999) {
                vibrated = false;
              }

              return Container(
                alignment: direction == SwipeDirection.endToStart
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.only(
                    right: direction == SwipeDirection.endToStart ? 24.0 : 0.0,
                    left: direction == SwipeDirection.startToEnd ? 24.0 : 0.0,
                  ),
                  child: Transform.scale(
                    scale: Tween<double>(
                      begin: 0,
                      end: 1.2,
                    )
                        .animate(
                          CurvedAnimation(
                            parent: progress,
                            curve: const Interval(
                              0.5,
                              1,
                            ),
                          ),
                        )
                        .value,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(
                          Icons.reply,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
        isEelevated: false,
        key: ValueKey('message;${widget.message}'),
        child: Padding(
          padding: EdgeInsets.only(
            left: !widget.sentBySelf ? 8.0 : 0.0,
            right: widget.sentBySelf ? 8.0 : 0.0,
          ),
          child: Align(
            alignment: widget.sentBySelf
                ? Alignment.centerRight
                : Alignment.centerLeft,
            child: Stack(
              children: [
                Positioned(
                  bottom: 10,
                  right: widget.sentBySelf ? 0 : null,
                  left: widget.sentBySelf ? null : 0,
                  child: ReactionsPreview(widget.message, widget.sentBySelf),
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: widget.sentBySelf
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onLongPressStart: widget.onLongPressed,
                      child: widget.bubble,
                    ),
                    if (widget.message.reactionsPreview.isNotEmpty)
                      // This SizedBox ensures that we have a proper bottom padding for the
                      // reaction preview, but also ensure that the Stack is wide enough
                      // so that the preview is not clipped by the Stack, since the overflow
                      // does not receive input events.
                      // See https://github.com/flutter/flutter/issues/19445
                      SizedBox(
                        height: 40,
                        width: MediaQuery.of(context).size.width,
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
