import 'dart:io';
import 'package:better_open_file/better_open_file.dart';
import 'package:flutter/material.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/shared/models/media.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/ui/widgets/chat/media/file.dart';
import 'package:moxxyv2/ui/widgets/chat/media/image.dart';
import 'package:moxxyv2/ui/widgets/chat/media/video.dart';
import 'package:moxxyv2/ui/widgets/chat/playbutton.dart';
import 'package:moxxyv2/ui/widgets/chat/quote/base.dart';
import 'package:moxxyv2/ui/widgets/chat/shared/file.dart';
import 'package:moxxyv2/ui/widgets/chat/shared/image.dart';
import 'package:moxxyv2/ui/widgets/chat/shared/video.dart';
import 'package:moxxyv2/ui/widgets/chat/text.dart';

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

    if (mime.startsWith('image/')) {
      return MessageType.image;
    } else if (mime.startsWith('video/')) {
      return MessageType.video;
    }
    // TODO(Unknown): Implement audio
    //else if (mime.startswith("audio/")) return MessageType.audio;

    return MessageType.file;
  }

  return MessageType.text;
}

/// Build an inlinable message widget
Widget buildMessageWidget(Message message, double maxWidth, BorderRadius radius, bool sent) {
  // Retracted messages are always rendered as a text message
  if (message.isRetracted) {
    return TextChatWidget(
      message,
      sent,
      topWidget: message.quotes != null ?
        buildQuoteMessageWidget(message.quotes!, sent) :
        null,
    );
  }

  switch (getMessageType(message)) {
    case MessageType.text: {
      return TextChatWidget(
        message,
        sent,
        topWidget: message.quotes != null ? buildQuoteMessageWidget(message.quotes!, sent) : null,
      );
    }
    case MessageType.image: {
      return ImageChatWidget(message, radius, maxWidth, sent);
    }
    case MessageType.video: {
      return VideoChatWidget(message, radius, maxWidth, sent);
    }
    // TODO(Unknown): Implement audio
    //case MessageType.audio: return buildImageMessageWidget(message);
    case MessageType.file: {
      return FileChatWidget(message, radius, sent);
    }
  }
}

/// Build a widget that represents a quoted message within another bubble.
Widget buildQuoteMessageWidget(Message message, bool sent, { void Function()? resetQuote}) {
  switch (getMessageType(message)) {
    case MessageType.text:
      return QuoteBaseWidget(message, Text(message.body), sent, resetQuotedMessage: resetQuote);
    case MessageType.image:
      return QuoteBaseWidget(
        message,
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    image: DecorationImage(
                      fit: BoxFit.cover,
                      image: FileImage(File(message.mediaUrl!)),
                    ),
                  ),
                  clipBehavior: Clip.hardEdge,
                ),
              ),
            ),
          ],
        ),
        sent,
        resetQuotedMessage: resetQuote,
      );
    case MessageType.video:
      return QuoteBaseWidget(
        message,
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            SizedBox(
              width: 48,
              height: 48,
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                child: Stack(
                  alignment: Alignment.center,
                  children: const [
                    Padding(
                      padding: EdgeInsets.all(32),
                      child: Icon(
                        Icons.error_outline,
                        size: 32,
                      ),
                    ),
                    PlayButton(size: 16)
                  ],
                ),
              ),
            )
          ],
        ),
        sent,
        resetQuotedMessage: resetQuote,
      );
    // TODO(Unknown): Implement audio
    //case MessageType.audio: return const SizedBox();
    case MessageType.file:
      return QuoteBaseWidget(
        message,
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(filenameFromUrl(message.srcUrl!)),
            ),
            SizedBox(
              width: 48,
              height: 48,
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                child: Stack(
                  alignment: Alignment.center,
                  children: const [
                    ColoredBox(
                      color: Colors.white60,
                    ),
                    Icon(
                      Icons.file_present,
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
        sent,
        resetQuotedMessage: resetQuote,
      );
  }
}

Widget buildSharedMediaWidget(SharedMedium medium, String conversationJid) {
  if (medium.mime == null) {
    return SharedFileWidget(
      medium.path,
    );
  } else if (medium.mime!.startsWith('image/')) {
    return SharedImageWidget(
      medium.path,
      onTap: () => OpenFile.open(medium.path),
    );
  } else if (medium.mime!.startsWith('video/')) {
    return SharedVideoWidget(
      medium.path,
      () => OpenFile.open(medium.path),
      child: const PlayButton(),
    );
  }
  // TODO(Unknown): Audio
  //if (message.mime!.startsWith("audio/")) return const SizedBox();

  return SharedFileWidget(medium.path);
}
