import 'package:flutter/material.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/widgets/chat/message/audio.dart';
import 'package:moxxyv2/ui/widgets/chat/message/file.dart';
import 'package:moxxyv2/ui/widgets/chat/message/image.dart';
import 'package:moxxyv2/ui/widgets/chat/message/sticker.dart';
import 'package:moxxyv2/ui/widgets/chat/message/text.dart';
import 'package:moxxyv2/ui/widgets/chat/message/video.dart';
import 'package:moxxyv2/ui/widgets/chat/quote/audio.dart';
import 'package:moxxyv2/ui/widgets/chat/quote/file.dart';
import 'package:moxxyv2/ui/widgets/chat/quote/image.dart';
import 'package:moxxyv2/ui/widgets/chat/quote/sticker.dart';
import 'package:moxxyv2/ui/widgets/chat/quote/text.dart';
import 'package:moxxyv2/ui/widgets/chat/quote/video.dart';

enum MessageType {
  text,
  image,
  video,
  audio,
  file,
  sticker,
}

/// Deduce the type of message we are dealing with to pick the correct
/// widget.
MessageType getMessageType(Message message) {
  if (message.isMedia) {
    if (message.stickerPackId != null) {
      return MessageType.sticker;
    }

    final mime = message.fileMetadata!.mimeType;
    if (mime == null) return MessageType.file;

    if (mime.startsWith('image/')) {
      return MessageType.image;
    } else if (mime.startsWith('video/')) {
      return MessageType.video;
    } else if (mime.startsWith('audio/')) {
      return MessageType.audio;
    }

    return MessageType.file;
  }

  return MessageType.text;
}

/// Build an inlinable message widget
Widget buildMessageWidget(
  Message message,
  bool isGroupchat,
  double maxWidth,
  BorderRadius radius,
  bool sent,
  double topLeftRadius,
  double topRightRadius,
) {
  // Retracted messages are always rendered as a text message
  if (message.isRetracted) {
    return TextChatWidget(
      message,
      sent,
      isGroupchat,
      topWidget: message.quotes != null
          ? buildQuoteMessageWidget(
              message.quotes!,
              sent,
              topLeftRadius,
              topRightRadius,
            )
          : null,
    );
  }

  switch (getMessageType(message)) {
    case MessageType.text:
      {
        return TextChatWidget(
          message,
          sent,
          isGroupchat,
          topWidget: message.quotes != null
              ? buildQuoteMessageWidget(
                  message.quotes!,
                  sent,
                  topLeftRadius,
                  topRightRadius,
                )
              : null,
        );
      }
    case MessageType.image:
      return ImageChatWidget(
        message,
        radius,
        maxWidth,
        sent,
        isGroupchat,
      );
    case MessageType.video:
      return VideoChatWidget(
        message,
        radius,
        maxWidth,
        sent,
        isGroupchat,
      );
    case MessageType.sticker:
      return StickerChatWidget(
        message,
        maxWidth,
        sent,
        quotedMessage: message.quotes != null
            ? buildQuoteMessageWidget(
                message.quotes!,
                sent,
                radiusLargeSize,
                radiusLargeSize,
              )
            : null,
      );
    case MessageType.audio:
      return AudioChatWidget(
        message,
        radius,
        maxWidth,
        sent,
        isGroupchat,
      );
    case MessageType.file:
      return FileChatWidget(
        message,
        radius,
        maxWidth,
        sent,
        isGroupchat,
      );
  }
}

/// Build a widget that represents a quoted message within another bubble.
Widget buildQuoteMessageWidget(
  Message message,
  bool sent,
  double topLeftRadius,
  double topRightRadius, {
  void Function()? resetQuote,
}) {
  switch (getMessageType(message)) {
    case MessageType.sticker:
      return QuotedStickerWidget(
        message,
        sent,
        topLeftRadius,
        topRightRadius,
        resetQuote: resetQuote,
      );
    case MessageType.text:
      return QuotedTextWidget(
        message,
        sent,
        topLeftRadius,
        topRightRadius,
        resetQuote: resetQuote,
      );
    case MessageType.image:
      return QuotedImageWidget(
        message,
        sent,
        topLeftRadius,
        topRightRadius,
        resetQuote: resetQuote,
      );
    case MessageType.video:
      return QuotedVideoWidget(
        message,
        sent,
        topLeftRadius,
        topRightRadius,
        resetQuote: resetQuote,
      );
    case MessageType.audio:
      return QuotedAudioWidget(
        message,
        sent,
        topLeftRadius,
        topRightRadius,
        resetQuote: resetQuote,
      );
    case MessageType.file:
      return QuotedFileWidget(
        message,
        sent,
        topLeftRadius,
        topRightRadius,
        resetQuote: resetQuote,
      );
  }
}
