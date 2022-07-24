import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/shared/models/media.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/ui/service/thumbnail.dart';
import 'package:moxxyv2/ui/widgets/chat/media/file.dart';
import 'package:moxxyv2/ui/widgets/chat/media/image.dart';
import 'package:moxxyv2/ui/widgets/chat/media/video.dart';
import 'package:moxxyv2/ui/widgets/chat/playbutton.dart';
import 'package:moxxyv2/ui/widgets/chat/quote/base.dart';
import 'package:moxxyv2/ui/widgets/chat/shared/file.dart';
import 'package:moxxyv2/ui/widgets/chat/shared/image.dart';
import 'package:moxxyv2/ui/widgets/chat/shared/video.dart';
import 'package:moxxyv2/ui/widgets/chat/text.dart';
import 'package:open_file/open_file.dart';

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
Widget buildMessageWidget(Message message, double maxWidth, BorderRadius radius) {
  switch (getMessageType(message)) {
    case MessageType.text: {
      return TextChatWidget(
        message,
        topWidget: message.quotes != null ? buildQuoteMessageWidget(message.quotes!) : null,
      );
    }
    case MessageType.image: {
      return ImageChatWidget(message, radius, maxWidth);
    }
    case MessageType.video: {
      return VideoChatWidget(message, radius, maxWidth);
    }
    // TODO(Unknown): Implement audio
    //case MessageType.audio: return buildImageMessageWidget(message);
    case MessageType.file: {
      return FileChatWidget(message);
    }
  }
}

/// Build a widget that represents a quoted message within another bubble.
Widget buildQuoteMessageWidget(Message message, { void Function()? resetQuote}) {
  switch (getMessageType(message)) {
    case MessageType.text:
      return QuoteBaseWidget(message, Text(message.body), resetQuotedMessage: resetQuote);
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
                child: FutureBuilder<Uint8List>(
                  future: GetIt.I.get<ThumbnailCacheService>().getImageThumbnail(message.mediaUrl!),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      if (snapshot.data != null) {
                        return Image.memory(
                          snapshot.data!,
                          fit: BoxFit.cover,
                        );
                      } else {
                        return const Padding(
                          padding: EdgeInsets.all(32),
                          child: Icon(
                            Icons.error_outline,
                            size: 32,
                          ),
                        );
                      }
                    } else {
                      return const CircularProgressIndicator();
                    }
                  },
                ),
              ),
            )
          ],
        ),
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
                  children: [
                    FutureBuilder<Uint8List>(
                      future: GetIt.I.get<ThumbnailCacheService>().getVideoThumbnail(message.mediaUrl!),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          if (snapshot.data != null) {
                            return Image.memory(
                              snapshot.data!,
                              fit: BoxFit.cover,
                            );
                          } else {
                            return const Padding(
                              padding: EdgeInsets.all(32),
                              child: Icon(
                                Icons.error_outline,
                                size: 32,
                              ),
                            );
                          }
                        } else {
                          return const CircularProgressIndicator();
                        }
                      },
                    ),
                    const PlayButton(size: 16)
                  ],
                ),
              ),
            )
          ],
        ),
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
                  children: [
                    Container(
                      decoration: const BoxDecoration(
                        color: Colors.white60,
                      ),
                    ),
                    const Icon(
                      Icons.file_present,
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
        resetQuotedMessage: resetQuote,
      );
  }
}

Widget buildSharedMediaWidget(SharedMedium medium, String conversationJid) {
  if (medium.mime == null) return SharedFileWidget(medium.path);

  if (medium.mime!.startsWith('image/')) {
    return SharedImageWidget(medium.path, () => OpenFile.open(medium.path));
  }
  if (medium.mime!.startsWith('video/')) return SharedVideoWidget(medium.path, conversationJid);
  // TODO(Unknown): Audio
  //if (message.mime!.startsWith("audio/")) return const SizedBox();

  return SharedFileWidget(medium.path);
}
