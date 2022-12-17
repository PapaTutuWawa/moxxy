// TODO(Unknown): The timestamp may be too light
// TODO(Unknown): The timestamp is too small
import 'package:flutter/material.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/shared/models/reaction.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/widgets/chat/datebubble.dart';
import 'package:moxxyv2/ui/widgets/chat/media/media.dart';
import 'package:moxxyv2/ui/widgets/chat/reactionbubble.dart';
import 'package:swipeable_tile/swipeable_tile.dart';

class RawChatBubble extends StatelessWidget {
  const RawChatBubble(
    this.message,
    this.maxWidth,
    this.sentBySelf,
    this.chatEncrypted,
    this.start,
    this.between,
    this.end,
    {
      super.key,
    }
  );
  final Message message;
  final double maxWidth;
  final bool sentBySelf;
  final bool chatEncrypted;
  final bool between;
  final bool end;
  final bool start;

  static BorderRadius getBorderRadius(bool sentBySelf, bool start, bool between, bool end) {
    return BorderRadius.only(
      topLeft: !sentBySelf && (between || end) && !(start && end) ? radiusSmall : radiusLarge,
      topRight: sentBySelf && (between || end) && !(start && end) ? radiusSmall : radiusLarge,
      bottomLeft: !sentBySelf && (between || start) && !(start && end) ? radiusSmall : radiusLarge,
      bottomRight: sentBySelf && (between || start) && !(start && end) ? radiusSmall : radiusLarge,
    );
  }
  
  /// Specified when the message bubble should not have color
  bool _shouldNotColorBubble() {
    var isInlinedWidget = false;
    if (message.mediaType != null) {
      isInlinedWidget = message.mediaType!.startsWith('image/');
    }

    // Check if it is an embedded file
    if (message.isMedia && message.mediaUrl != null && isInlinedWidget) {
      return true;
    }

    // Stickers are also not colored
    return message.stickerPackId != null && message.stickerId != null;
  }

  Color? _getBubbleColor(BuildContext context) {
    if (_shouldNotColorBubble()) return null;

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
    return Container(
      constraints: BoxConstraints(
        maxWidth: maxWidth,
      ),
      decoration: BoxDecoration(
        color: _getBubbleColor(context),
        borderRadius: borderRadius,
      ),
      child: Padding(
        // NOTE: Images don't work well with padding here
        padding: message.isMedia || message.quotes != null ?
        EdgeInsets.zero :
        const EdgeInsets.all(8),
        child: buildMessageWidget(
          message,
          maxWidth,
          borderRadius,
          sentBySelf,
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
    required this.lastMessageTimestamp,
    required this.onSwipedCallback,
    required this.bubble,
    this.onLongPressed,
    this.onReactionTap,
    super.key,
  });
  final Message message;
  final bool sentBySelf;
  // For rendering the corners
  final double maxWidth;
  // For rendering the date bubble
  final int? lastMessageTimestamp;
  // For acting on swiping
  final void Function(Message) onSwipedCallback;
  // For acting on long-pressing the message
  final GestureLongPressStartCallback? onLongPressed;
  // The actual message bubble
  final RawChatBubble bubble;
  // For acting on reaction taps
  final void Function(Reaction)? onReactionTap;

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

    return widget.sentBySelf ? SwipeDirection.endToStart : SwipeDirection.startToEnd;
  }

  Widget _buildReactions() {
    if (widget.message.reactions.isEmpty) {
      return const SizedBox();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 1),
      child: Wrap(
        spacing: 1,
        runSpacing: 2,
        children: widget.message.reactions.map(
          (reaction) => ReactionBubble(
            emoji: reaction.emoji,
            reactions: reaction.reactions,
            reactedTo: reaction.reactedBySelf,
            sentBySelf: widget.sentBySelf,
            onTap: widget.onReactionTap != null ?
              () => widget.onReactionTap!(reaction) :
              null,
          ),
        ).toList(),
      ),
    );
  }
  
  Widget _buildBubble(BuildContext context) {
    return SwipeableTile.swipeToTrigger(
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
              Vibrate.feedback(FeedbackType.light);
              vibrated = true;
            } else if (progress.value < 0.9999) {
              vibrated = false;
            }

            return Container(
              alignment: direction == SwipeDirection.endToStart ? Alignment.centerRight : Alignment.centerLeft,
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
                      curve: const Interval(0.5, 1,),
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
          alignment: widget.sentBySelf ?
            Alignment.centerRight :
            Alignment.centerLeft,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: widget.sentBySelf ?
                CrossAxisAlignment.end :
                CrossAxisAlignment.start,
              children: [
                GestureDetector(
                  onLongPressStart: widget.onLongPressed,
                  child: widget.bubble,
                ),

                _buildReactions(),
              ],
            ),
          ),
      ),
    );
  }

  Widget _buildWithDateBubble(Widget widget, String dateString) {
    return IntrinsicHeight(
      child: Column(
        children: [
          DateBubble(dateString),
          widget,
        ],
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    super.build(context);
    // lastMessageTimestamp == null means that there is no previous message
    final thisMessageDateTime = DateTime.fromMillisecondsSinceEpoch(widget.message.timestamp);
    if (widget.lastMessageTimestamp == null) {
      return _buildWithDateBubble(
        _buildBubble(context),
        formatDateBubble(thisMessageDateTime, DateTime.now()),
      );
    }

    final lastMessageDateTime = DateTime.fromMillisecondsSinceEpoch(widget.lastMessageTimestamp!);

    if (lastMessageDateTime.day != thisMessageDateTime.day ||
        lastMessageDateTime.month != thisMessageDateTime.month ||
        lastMessageDateTime.year != thisMessageDateTime.year) {
      return _buildWithDateBubble(
        _buildBubble(context),
        formatDateBubble(thisMessageDateTime, DateTime.now()),
      );
    }

    return _buildBubble(context);
  }
}
