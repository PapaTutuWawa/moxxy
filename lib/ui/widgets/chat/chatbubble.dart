// TODO(Unknown): The timestamp may be too light
// TODO(Unknown): The timestamp is too small
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/error_types.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/shared/warning_types.dart';
import 'package:moxxyv2/ui/bloc/conversation_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/ui/widgets/chat/datebubble.dart';
import 'package:moxxyv2/ui/widgets/chat/media/media.dart';
import 'package:moxxyv2/ui/widgets/overview_menu.dart';
import 'package:swipeable_tile/swipeable_tile.dart';

Widget _buildMessageOption(IconData icon, String text, void Function() callback) {
  return InkResponse(
    onTap: callback,
    child: Row(
      children: [
        Padding(
          padding: const EdgeInsets.only(
            top: 8,
            right: 8,
            bottom: 8,
          ),
          child: Icon(icon),
        ),
        Text(text),
      ],
    ),
  );
}

class ChatBubble extends StatefulWidget {
  const ChatBubble({
    required this.message,
    required this.sentBySelf,
    required this.chatEncrypted,
    required this.between,
    required this.start,
    required this.end,
    required this.maxWidth,
    required this.lastMessageTimestamp,
    required this.onSwipedCallback,
    super.key,
  });
  final Message message;
  final bool sentBySelf;
  final bool chatEncrypted;
  // For rendering the corners
  final bool between;
  final bool start;
  final bool end;
  final double maxWidth;
  // For rendering the date bubble
  final int? lastMessageTimestamp;
  // For acting on swiping
  final void Function(Message) onSwipedCallback;

  @override
  ChatBubbleState createState() => ChatBubbleState();
}

class ChatBubbleState extends State<ChatBubble>
  with AutomaticKeepAliveClientMixin<ChatBubble>, TickerProviderStateMixin {

  late final AnimationController _controller = AnimationController(
    duration: const Duration(milliseconds: 200),
    vsync: this,
  );

  late Animation<double> _msgY;
  //late Animation<double> _msgX;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
  
  @override
  bool get wantKeepAlive => true;
    
  BorderRadius _getBorderRadius() {
    return BorderRadius.only(
      topLeft: !widget.sentBySelf && (widget.between || widget.end) && !(widget.start && widget.end) ? radiusSmall : radiusLarge,
      topRight: widget.sentBySelf && (widget.between || widget.end) && !(widget.start && widget.end) ? radiusSmall : radiusLarge,
      bottomLeft: !widget.sentBySelf && (widget.between || widget.start) && !(widget.start && widget.end) ? radiusSmall : radiusLarge,
      bottomRight: widget.sentBySelf && (widget.between || widget.start) && !(widget.start && widget.end) ? radiusSmall : radiusLarge,
    );
  }

  /// Returns true if the mime type has a special widget which replaces the bubble.
  /// False otherwise.
  bool _isInlinedWidget() {
    if (widget.message.mediaType != null) {
      return widget.message.mediaType!.startsWith('image/');
    }

    return false;
  }
  
  /// Specified when the message bubble should not have color
  bool _shouldNotColorBubble() {
    return widget.message.isMedia && widget.message.mediaUrl != null && _isInlinedWidget();
  }

  Color? _getBubbleColor(BuildContext context) {
    if (_shouldNotColorBubble()) return null;

    // Color the bubble red if it should be encrypted but is not.
    if (widget.chatEncrypted && !widget.message.encrypted) {
      return bubbleColorUnencrypted;
    }

    if (widget.message.isRetracted) {
      if (widget.sentBySelf) {
        return const Color(0xff614d91);
      } else {
        return const Color(0xff585858);
      }
    }
    
    if (widget.sentBySelf) {
      return bubbleColorSent;
    } else {
      return bubbleColorReceived;
    }
  }

  SwipeDirection _getSwipeDirection() {
    // Should the message be quotable?
    if (!widget.message.isQuotable) {
      return SwipeDirection.none;
    }

    return widget.sentBySelf ? SwipeDirection.endToStart : SwipeDirection.startToEnd;
  }

  /// Called when the user wants to retract the message
  Future<void> _retractMessage(BuildContext context) async {
    final result = await showConfirmationDialog(
      t.pages.conversation.retract,
      t.pages.conversation.retractBody,
      context,
    );

    if (result) {
      // ignore: use_build_context_synchronously
      context.read<ConversationBloc>().add(
        MessageRetractedEvent(widget.message.originId!),
      );

      // ignore: use_build_context_synchronously
      Navigator.of(context).pop();
    }
  }
  
  Widget _buildBubble(BuildContext context) {
    final message = Container(
      constraints: BoxConstraints(
        maxWidth: widget.maxWidth,
      ),
      decoration: BoxDecoration(
        color: _getBubbleColor(context),
        borderRadius: _getBorderRadius(),
      ),
      child: Padding(
        // NOTE: Images don't work well with padding here
        padding: widget.message.isMedia || widget.message.quotes != null ?
        EdgeInsets.zero :
        const EdgeInsets.all(8),
        child: buildMessageWidget(
          widget.message,
          widget.maxWidth,
          _getBorderRadius(),
          widget.sentBySelf,
        ),
      ),
    );

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
        child: Row(
          mainAxisAlignment: widget.sentBySelf ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            GestureDetector(
              onLongPressStart: (event) async {
                if (!widget.message.isLongpressable) {
                  return;
                }

                Vibrate.feedback(FeedbackType.medium);

                _msgY = Tween<double>(
                  begin: event.globalPosition.dy - 20,
                  end: 200,
                ).animate(
                  CurvedAnimation(
                    parent: _controller,
                    curve: Curves.easeInOutCubic,
                  ),
                );
                // TODO(PapaTutuWawa): Animate the message to the center?
                /*_msgX = Tween<double>(
                  begin: 8,
                  end: (MediaQuery.of(context).size.width - obj.paintBounds.width) / 2,
                ).animate(_controller);*/

                await _controller.forward();
                await showDialog<void>(
                  context: context,
                  builder: (context) => OverviewMenu(
                    _msgY,
                    rightBorder: widget.sentBySelf,
                    left: widget.sentBySelf ? null : 8,
                    right: widget.sentBySelf ? 8 : null,
                    highlightMaterialBorder: _getBorderRadius(),
                    highlight: message,
                    children: [
                      ...widget.message.canRetract(widget.sentBySelf) ? [
                        _buildMessageOption(
                          Icons.delete,
                          t.pages.conversation.retract,
                          () => _retractMessage(context),
                        ),
                      ] : [],
                      ...widget.message.canEdit(widget.sentBySelf) ? [
                        _buildMessageOption(
                          Icons.edit,
                          t.pages.conversation.edit,
                          () {
                            showNotImplementedDialog(
                              'editing',
                              context,
                            );
                          },
                        ),
                      ] : [],
                      ...widget.message.errorMenuVisible ? [
                        _buildMessageOption(
                          Icons.info_outline,
                          'Show Error',
                          () {
                            showInfoDialog(
                              'Error',
                              errorToTranslatableString(widget.message.errorType!),
                              context,
                            );
                          },
                        ),
                      ] : [],
                      ...widget.message.hasWarning ? [
                        _buildMessageOption(
                          Icons.warning,
                          'Show warning',
                          () {
                            showInfoDialog(
                              'Warning',
                              warningToTranslatableString(widget.message.warningType!),
                              context,
                            );
                          },
                        ),
                      ] : [],
                      ...widget.message.isQuotable ? [
                        _buildMessageOption(
                          Icons.forward,
                          t.pages.conversation.forward,
                          () {
                            showNotImplementedDialog(
                              'sharing',
                              context,
                            );
                          },
                        ),
                      ] : [],
                      _buildMessageOption(
                        Icons.reply,
                        t.pages.conversation.quote,
                        () {
                          widget.onSwipedCallback(widget.message);
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                );

                await _controller.reverse();
              },
              child: message,
            ), 
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
