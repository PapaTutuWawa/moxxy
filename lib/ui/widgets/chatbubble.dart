import "dart:async";
import "dart:math";

import "package:moxxyv2/shared/helpers.dart";
import "package:moxxyv2/shared/models/message.dart";
import "package:moxxyv2/ui/constants.dart";
import "package:moxxyv2/ui/widgets/quotedmessage.dart";
import "package:moxxyv2/ui/widgets/chat/download.dart";
import "package:moxxyv2/ui/widgets/chat/downloadbutton.dart";
import "package:moxxyv2/ui/widgets/chat/blurhash.dart";
import "package:moxxyv2/ui/widgets/chat/image.dart";
import "package:moxxyv2/ui/widgets/chat/video.dart";
import "package:moxxyv2/ui/widgets/chat/file.dart";
import "package:moxxyv2/ui/widgets/chat/text.dart";

// TODO: Maybe move this out of the UI code
import "package:moxxyv2/shared/commands.dart";

// TODO: The timestamp may be too light
// TODO: The timestamp is too small
import "package:flutter/material.dart";
import "package:path/path.dart" as path;

// TODO: Maybe move this out of the UI code
import "package:flutter_background_service/flutter_background_service.dart";

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

  Size _getThumbnailSize() {
    final size = message.thumbnailDimensions?.split("x");
    double width = maxWidth;
    double height = maxWidth;
    if (size != null) {
      final dimWidth = int.parse(size[0]).toDouble();
      final dimHeight = int.parse(size[1]).toDouble();
      width = min(dimWidth, maxWidth);
      height = ((width / dimWidth) * dimHeight);
    }

    return Size(width, height);
  }

  void _requestDownload() {
    FlutterBackgroundService().sendData(
      PerformDownloadAction(message: message).toJson()
    );
  }
  
  Widget _buildBody() {
    if (message.quotes != null) {
      // TODO: Handle media messages being quoted
      return TextChatWidget(
        body: message.body,
        timestamp: _timestampString,
        received: message.received,
        displayed: message.displayed,
        acked: message.acked,
        enablePadding: true,
        topWidget: QuotedMessageWidget(message: message.quotes!)
      );
    }

    if (message.isMedia) {
      if (message.mediaUrl != null) {
        final mime = message.mediaType;
        if (mime == null) {
          // Fall through
        } else if (mime.startsWith("image/")) {
          return ImageChatWidget(
            path: message.mediaUrl!,
            timestamp: _timestampString,
            radius: _getBorderRadius(),
            thumbnailData: message.thumbnailData,
            thumbnailSize: _getThumbnailSize(),
            received: message.received,
            displayed: message.displayed,
            acked: message.acked
          );
        } else if (mime.startsWith("video/")) {
          return VideoChatWidget(
            path: message.mediaUrl!,
            timestamp: _timestampString,
            radius: _getBorderRadius(),
            thumbnailData: message.thumbnailData,
            thumbnailSize: _getThumbnailSize(),
            conversationJid: message.conversationJid,
            received: message.received,
            displayed: message.displayed,
            acked: message.acked
          );
        }

        return FileChatWidget(
          path: message.mediaUrl!,
          filename: path.basename(message.mediaUrl!),
          timestamp: _timestampString,
          received: message.received,
          displayed: message.displayed,
          acked: message.acked
        );
      } else {
        if (message.isDownloading) {
          if (message.thumbnailData != null) {
            final size = _getThumbnailSize();

            return BlurhashChatWidget(
              width: size.width.toInt(),
              height: size.height.toInt(),
              borderRadius: _getBorderRadius(),
              thumbnailData: message.thumbnailData!,
              child: DownloadProgress(id: message.id)
            );
          } else {
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: DownloadProgress(id: message.id)
            );
          }
        } else {
          // This means that the file is not yet downloaded

          if (message.thumbnailData != null) {
            final size = _getThumbnailSize();

            return BlurhashChatWidget(
              width: size.width.toInt(),
              height: size.height.toInt(),
              borderRadius: _getBorderRadius(),
              thumbnailData: message.thumbnailData!,
              child: DownloadButton(
                onPressed: () => _requestDownload()
              )
            );
          } else {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: FileChatWidget(
                // NOTE: This may crash if run with a database from before srcUrl was implemented, but no need to guard against it
                filename: path.basename(message.srcUrl!),
                path: "",
                timestamp: _timestampString,
                received: message.received,
                displayed: message.displayed,
                acked: message.acked,
                extra: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ElevatedButton(
                    onPressed: () => _requestDownload(),
                    child: const Text("Download")
                  )
                )
              )
            );
          }
        }
      }
    }

    return TextChatWidget(
      body: message.body,
      timestamp: _timestampString,
      received: message.received,
      displayed: message.displayed,
      acked: message.acked,
      enablePadding: false
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
              padding: message.isMedia || message.quotes != null ? const EdgeInsets.all(0.0) : const EdgeInsets.all(8.0),
              child: _buildBody()
            )
          )
        ]
      )
    );
  }
}
