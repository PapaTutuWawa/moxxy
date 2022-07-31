// TODO(Unknown): The timestamp may be too light
// TODO(Unknown): The timestamp is too small
import 'package:flutter/material.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/widgets/chat/datebubble.dart';
import 'package:moxxyv2/ui/widgets/chat/media/media.dart';
import 'package:swipeable_tile/swipeable_tile.dart';

class ChatBubble extends StatelessWidget {

  const ChatBubble({
      required this.message,
      required this.sentBySelf,
      required this.between,
      required this.start,
      required this.end,
      required this.maxWidth,
      required this.lastMessageTimestamp,
      required this.onSwipedCallback,
      Key? key,
  }) : super(key: key);
  final Message message;
  final bool sentBySelf;
  // For rendering the corners
  final bool between;
  final bool start;
  final bool end;
  final double maxWidth;
  // For rendering the date bubble
  final int? lastMessageTimestamp;
  // For acting on swiping
  final void Function(Message) onSwipedCallback;
  
  BorderRadius _getBorderRadius() {
    return BorderRadius.only(
      topLeft: !sentBySelf && (between || end) && !(start && end) ? radiusSmall : radiusLarge,
      topRight: sentBySelf && (between || end) && !(start && end) ? radiusSmall : radiusLarge,
      bottomLeft: !sentBySelf && (between || start) && !(start && end) ? radiusSmall : radiusLarge,
      bottomRight: sentBySelf && (between || start) && !(start && end) ? radiusSmall : radiusLarge,
    );
  }

  /// Returns true if the mime type has a special widget which replaces the bubble.
  /// False otherwise.
  bool _isInlinedWidget() {
    if (message.mediaType != null) {
      return message.mediaType!.startsWith('image/');
    }

    return false;
  }
  
  /// Specified when the message bubble should not have color
  bool _shouldNotColorBubble() {
    return message.isMedia && message.mediaUrl != null && _isInlinedWidget();
  }

  Color? _getBubbleColor(BuildContext context) {
    if (_shouldNotColorBubble()) return null;

    if (sentBySelf) {
      return bubbleColorSent;
    } else {
      return bubbleColorReceived;
    }
  }

  Widget _buildBubble(BuildContext context) {
    return SwipeableTile.swipeToTrigger(
      direction: SwipeDirection.horizontal,
      swipeThreshold: 0.2,
      onSwiped: (_) => onSwipedCallback(message),
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
      key: ValueKey('message;$message'),
      child: Padding(
        padding: EdgeInsets.only(
          left: !sentBySelf ? 8.0 : 0.0,
          right: sentBySelf ? 8.0 : 0.0,
        ),
        child: Row(
          mainAxisAlignment: sentBySelf ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            Container(
              constraints: BoxConstraints(
                maxWidth: maxWidth,
              ),
              decoration: BoxDecoration(
                color: _getBubbleColor(context),
                borderRadius: _getBorderRadius(),
              ),
              child: Padding(
                // NOTE: Images don't work well with padding here
                padding: message.isMedia || message.quotes != null ? EdgeInsets.zero : const EdgeInsets.all(8),
                child: buildMessageWidget(message, maxWidth, _getBorderRadius()),
              ),
            )
          ],
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
    // lastMessageTimestamp == null means that there is no previous message
    final thisMessageDateTime = DateTime.fromMillisecondsSinceEpoch(message.timestamp);
    if (lastMessageTimestamp == null) {
      return _buildWithDateBubble(
        _buildBubble(context),
        formatDateBubble(thisMessageDateTime, DateTime.now()),
      );
    }

    final lastMessageDateTime = DateTime.fromMillisecondsSinceEpoch(lastMessageTimestamp!);

    if (lastMessageDateTime.day != thisMessageDateTime.day ||
        lastMessageDateTime.month != thisMessageDateTime.month ||
        lastMessageDateTime.year != thisMessageDateTime.year) {
      return _buildWithDateBubble(
        _buildBubble(context),
        formatDateBubble(lastMessageDateTime, DateTime.now()),
      );
    }

    return _buildBubble(context);
  }
}
