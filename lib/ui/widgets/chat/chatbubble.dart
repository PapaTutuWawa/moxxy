import "dart:async";

import "package:moxxyv2/shared/helpers.dart";
import "package:moxxyv2/shared/models/message.dart";
import "package:moxxyv2/ui/constants.dart";
//import "package:moxxyv2/ui/widgets/chat/download.dart";
//import "package:moxxyv2/ui/widgets/chat/downloadbutton.dart";
//import "package:moxxyv2/ui/widgets/chat/blurhash.dart";
//import "package:moxxyv2/ui/widgets/chat/image.dart";
//import "package:moxxyv2/ui/widgets/chat/video.dart";
//import "package:moxxyv2/ui/widgets/chat/file.dart";
//import "package:moxxyv2/ui/widgets/chat/text.dart";
import "package:moxxyv2/ui/widgets/chat/media/media.dart";

// TODO: Maybe move this out of the UI code
//import "package:moxxyv2/shared/commands.dart";

// TODO: The timestamp may be too light
// TODO: The timestamp is too small
import "package:flutter/material.dart";
//import "package:path/path.dart" as path;

// TODO: Maybe move this out of the UI code
//import "package:flutter_background_service/flutter_background_service.dart";

class ChatBubble extends StatefulWidget {
  final Message message;
  final bool sentBySelf;
  // 
  final bool between;
  final bool start;
  final bool end;
  final double maxWidth;

  const ChatBubble({
      required this.message,
      required this.sentBySelf,
      required this.between,
      required this.start,
      required this.end,
      required this.maxWidth,
      Key? key
  }) : super(key: key);

  @override
  // ignore: no_logic_in_create_state
  _ChatBubbleState createState() => _ChatBubbleState(
      message: message,
      sentBySelf: sentBySelf,
      between: between,
      start: start,
      end: end,
      maxWidth: maxWidth
  );
}

class _ChatBubbleState extends State<ChatBubble> {
  final Message message;
  final bool sentBySelf;
  // 
  final bool between;
  final bool start;
  final bool end;
  final double maxWidth;

  late String _timestampString;
  late Timer? _updateTimer;

  _ChatBubbleState({
      required this.message,
      required this.sentBySelf,
      required this.between,
      required this.start,
      required this.end,
      required this.maxWidth
  }) {
    // Different name for now to prevent possible shadowing issues
    final _now = DateTime.now().millisecondsSinceEpoch;
    _timestampString = formatMessageTimestamp(message.timestamp, _now);

    // Only start the timer if neccessary
    if (_now - message.timestamp <= 15 * Duration.millisecondsPerMinute) {
      _updateTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
          setState(() {
              final now = DateTime.now().millisecondsSinceEpoch;
              _timestampString = formatMessageTimestamp(message.timestamp, now);

              if (now - message.timestamp > 15 * Duration.millisecondsPerMinute) {
                _updateTimer!.cancel();
              }
          });
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

  BorderRadius _getBorderRadius() {
    return BorderRadius.only(
      topLeft: !sentBySelf && (between || end) && !(start && end) ? radiusSmall : radiusLarge,
      topRight: sentBySelf && (between || end) && !(start && end) ? radiusSmall : radiusLarge,
      bottomLeft: !sentBySelf && (between || start) && !(start && end) ? radiusSmall : radiusLarge,
      bottomRight: sentBySelf && (between || start) && !(start && end) ? radiusSmall : radiusLarge
    );
  }

  /// Returns true if the mime type has a special widget which replaces the bubble.
  /// False otherwise.
  bool _isInlinedWidget() {
    if (message.mediaType != null) {
      return message.mediaType!.startsWith("image/");
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
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: !sentBySelf ? 8.0 : 0.0,
        right: sentBySelf ? 8.0 : 0.0
      ),
      child: Row(
        mainAxisAlignment: sentBySelf ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: maxWidth
            ),
            decoration: BoxDecoration(
              color: _getBubbleColor(context),
              borderRadius: _getBorderRadius()
            ),
            child: Padding(
              // NOTE: Images don't work well with padding here
              padding: message.isMedia || message.quotes != null ? const EdgeInsets.all(0.0) : const EdgeInsets.all(8.0),
              child: buildMessageWidget(message, _timestampString, maxWidth, _getBorderRadius())
            )
          )
        ]
      )
    );
  }
}
