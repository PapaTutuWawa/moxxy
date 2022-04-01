import "dart:io";

import "package:moxxyv2/shared/models/message.dart";
import "package:moxxyv2/ui/widgets/chat/text.dart";
import "package:moxxyv2/ui/widgets/chat/media/image.dart";
import "package:moxxyv2/ui/widgets/chat/media/file.dart";
import "package:moxxyv2/ui/widgets/chat/media/video.dart";
import "package:moxxyv2/ui/widgets/chat/quote/base.dart";

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
Widget buildMessageWidget(Message message, double maxWidth, BorderRadius radius) {
  switch (getMessageType(message)) {
    case MessageType.text: {
      return TextChatWidget(
        message,
        enablePadding: false,
        topWidget: message.quotes != null ? buildQuoteMessageWidget(message.quotes!) : null
      );
    }
    case MessageType.image: {
      return ImageChatWidget(message, radius, maxWidth);
    }
    case MessageType.video: {
      return VideoChatWidget(message, radius, maxWidth);
    }
    // TODO
    //case MessageType.audio: return buildImageMessageWidget(message);
    case MessageType.file: {
      return FileChatWidget(message);
    }
  }
}

/// Build a widget that represents a quoted message within another bubble.
Widget buildQuoteMessageWidget(Message message, { void Function()? resetQuote}) {
  switch (getMessageType(message)) {
    case MessageType.text: {
      return QuoteBaseWidget(message, Text(message.body), resetQuotedMessage: resetQuote);
    }
    // TODO
    case MessageType.image: {
      return QuoteBaseWidget(
        message,
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(
              width: 48.0,
              height: 48.0,
              // TODO: Error handling
              child: ClipRRect(
                borderRadius: BorderRadius.all(Radius.circular(8.0)),
                child: Image.file(
                  File(message.mediaUrl!),
                  fit: BoxFit.cover,
                )
              )
            )
          ]
        ),
        resetQuotedMessage: resetQuote
      );
    }
    case MessageType.video: return const SizedBox();
    //case MessageType.audio: return const SizedBox();
    case MessageType.file: return const SizedBox();
  }
}
