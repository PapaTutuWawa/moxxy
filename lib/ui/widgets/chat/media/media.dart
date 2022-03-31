import "package:moxxyv2/shared/models/message.dart";
import "package:moxxyv2/ui/widgets/chat/text.dart";
import "package:moxxyv2/ui/widgets/chat/media/image.dart";
import "package:moxxyv2/ui/widgets/chat/media/file.dart";
import "package:moxxyv2/ui/widgets/chat/media/video.dart";

import "package:flutter/material.dart";

enum MessageType {
  text,
  image,
  video,
  // audio
  file
}

/// Deduce the type of message we are dealing with to pick the correct
/// widget.
MessageType getMessageType(Message message) {
  if (message.isMedia) {
    final mime = message.mediaType;
    print(mime);
    if (mime == null) return MessageType.file;

    if (mime.startsWith("image/")) return MessageType.image;
    else if (mime.startsWith("video/")) return MessageType.video;
    // TODO
    //else if (mime.startswith("audio/")) return MessageType.audio;

    return MessageType.file;
  }

  return MessageType.text;
}

/// Build an inlinable message widget
Widget buildMessageWidget(Message message, String timestamp, double maxWidth, BorderRadius radius) {
  print(message.srcUrl);
  switch (getMessageType(message)) {
    case MessageType.text: {
      return TextChatWidget(
        message,
        timestamp,
        enablePadding: false
      );
    }
    case MessageType.image: {
      return ImageChatWidget(message, timestamp, radius, maxWidth);
    }
    case MessageType.video: {
      return VideoChatWidget(message, timestamp, radius, maxWidth);
    }
    // TODO
    //case MessageType.audio: return buildImageMessageWidget(message);
    case MessageType.file: {
      return FileChatWidget(message, timestamp);
    }
  }
}

/// Build a widget that represents a quoted message within another bubble.
/*Widget buildQuoteMessageWidget(Message message) {
  switch (getMessageType(message)) {
    case MessageType.text: return TextChatWidget(
      message: message
      enablePadding: false
    );
    case MessageType.image: return buildImageMessageWidget(message);
    case MessageType.video: return buildVideoMessageWidget(message);
    //case MessageType.audio: return buildImageMessageWidget(message);
    case MessageType.file: return buildFileMessageWidget(message);
  }
}*/
