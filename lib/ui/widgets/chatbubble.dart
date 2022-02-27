import "dart:async";

import "package:moxxyv2/shared/helpers.dart";
import "package:moxxyv2/shared/models/message.dart";
import "package:moxxyv2/ui/constants.dart";
import "package:moxxyv2/ui/service/download.dart";
import "package:moxxyv2/ui/widgets/chat/image.dart";
import "package:moxxyv2/ui/widgets/chat/file.dart";
import "package:moxxyv2/ui/widgets/chat/text.dart";

// TODO: The timestamp may be too light
// TODO: The timestamp is too small
import "package:flutter/material.dart";
import "package:get_it/get_it.dart";
import "package:path/path.dart" as path;

class ChatBubble extends StatefulWidget {
  final Message message;
  final bool sentBySelf;
  // 
  final bool closerTogether;
  final bool between;
  final bool start;
  final bool end;
  final double maxWidth;

  const ChatBubble({
      required this.message,
      required this.sentBySelf,
      required this.closerTogether,
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
      closerTogether: closerTogether,
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
  final bool closerTogether;
  final bool between;
  final bool start;
  final bool end;
  final double maxWidth;

  double _downloadProgress;
  late String _timestampString;
  late Timer? _updateTimer;

  _ChatBubbleState({
      required this.message,
      required this.sentBySelf,
      required this.closerTogether,
      required this.between,
      required this.start,
      required this.end,
      required this.maxWidth
  }): _downloadProgress = 0.0 {
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

    if (message.isMedia && message.mediaUrl == null && message.isDownloading) {
      GetIt.I.get<UIDownloadService>().registerCallback(message.id, _onProgressUpdate);
    }
  }

  void _onProgressUpdate(double progress) {
    setState(() {
        _downloadProgress = progress;
    });
  }
  
  @override
  void dispose() {
    if (_updateTimer != null) {
      _updateTimer!.cancel();
    }

    GetIt.I.get<UIDownloadService>().unregisterCallback(message.id);
    
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
  
  Widget _buildBody() {
    if (message.isMedia) {
      if (message.mediaUrl != null) {
        final mime = message.mediaType;
        if (mime == null) {
          // Fall through
        } else if (mime.startsWith("image/")) {
          return ImageChatWidget(
            path: message.mediaUrl!,
            timestamp: _timestampString,
            radius: _getBorderRadius()
          );
        }

        return FileChatWidget(
          path: message.mediaUrl!,
          filename: path.basename(message.mediaUrl!),
          timestamp: _timestampString
        );
      } else {
        if (message.isDownloading) {
          // TODO: If we have a thumbnail, inline it like a regular image and place the
          //       spinner over it
          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: CircularProgressIndicator(value: _downloadProgress)
          );
        } else {
          // TODO: Put a button here if the user is not in our roster
          // TODO: If we have a thumbnail, inline it like a regular image and place the
          //       button over it
        }
      }
    }

    return TextChatWidget(
      body: message.body,
      timestamp: _timestampString
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
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: !sentBySelf ? 8.0 : 0.0, // Conditional
        right: sentBySelf ? 8.0 : 0.0,
        top: 1.0,
        bottom: closerTogether ? 1.0 : 8.0
      ),
      child: Row(
        mainAxisAlignment: sentBySelf ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: maxWidth
            ),
            decoration: BoxDecoration(
              color: _shouldNotColorBubble() ? null : (sentBySelf ? bubbleColorSent : bubbleColorReceived),
              borderRadius: _getBorderRadius()
            ),
            child: Padding(
              // NOTE: Images don't work well with padding here
              padding: message.isMedia ? const EdgeInsets.all(0.0) : const EdgeInsets.all(8.0),
              child: _buildBody()
            )
          )
        ]
      )
    );
  }
}
