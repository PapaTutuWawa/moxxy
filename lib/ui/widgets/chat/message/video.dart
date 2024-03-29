import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/ui/widgets/chat/bottom.dart';
import 'package:moxxyv2/ui/widgets/chat/downloadbutton.dart';
import 'package:moxxyv2/ui/widgets/chat/helpers.dart';
import 'package:moxxyv2/ui/widgets/chat/message/base.dart';
import 'package:moxxyv2/ui/widgets/chat/message/file.dart';
import 'package:moxxyv2/ui/widgets/chat/playbutton.dart';
import 'package:moxxyv2/ui/widgets/chat/progress.dart';
import 'package:moxxyv2/ui/widgets/chat/video_thumbnail.dart';
import 'package:moxxyv2/ui/widgets/chat/viewers/video.dart';

class VideoChatWidget extends StatelessWidget {
  const VideoChatWidget(
    this.message,
    this.radius,
    this.maxWidth,
    this.sent,
    this.isGroupchat, {
    super.key,
  });
  final Message message;
  final double maxWidth;
  final BorderRadius radius;
  final bool sent;

  /// Whether the message was sent in a groupchat context or not.
  final bool isGroupchat;

  Widget _buildUploading() {
    return MediaBaseChatWidget(
      VideoThumbnail(
        path: message.fileMetadata!.path!,
        conversationJid: message.conversationJid,
        mime: message.fileMetadata!.mimeType!,
        size: Size(
          maxWidth,
          0.6 * maxWidth,
        ),
        borderRadius: radius,
      ),
      MessageBubbleBottom(message, sent),
      radius,
      sent,
      message.senderJid,
      isGroupchat,
      extra: ProgressWidget(message.id),
    );
  }

  Widget _buildDownloading() {
    if (message.fileMetadata!.thumbnailData != null) {
      final size = getMediaSize(message, maxWidth);

      return MediaBaseChatWidget(
        SizedBox(
          width: size.width,
          height: size.height,
          child: BlurHash(
            hash: message.fileMetadata!.thumbnailData!,
            decodingWidth: size.width.toInt(),
            decodingHeight: size.height.toInt(),
          ),
        ),
        MessageBubbleBottom(message, sent),
        radius,
        sent,
        message.senderJid,
        isGroupchat,
        extra: ProgressWidget(message.id),
      );
    } else {
      return FileChatBaseWidget(
        message,
        message.fileMetadata!.filename,
        radius,
        maxWidth,
        sent,
        isGroupchat,
        mimeType: message.fileMetadata!.mimeType,
        downloadButton: ProgressWidget(message.id),
      );
    }
  }

  /// The video exists locally
  Widget _buildVideo(BuildContext context) {
    return MediaBaseChatWidget(
      VideoThumbnail(
        path: message.fileMetadata!.path!,
        conversationJid: message.conversationJid,
        mime: message.fileMetadata!.mimeType!,
        size: Size(
          maxWidth,
          0.6 * maxWidth,
        ),
        borderRadius: radius,
      ),
      MessageBubbleBottom(
        message,
        sent,
      ),
      radius,
      sent,
      message.senderJid,
      isGroupchat,
      onTap: () {
        showVideoViewer(
          context,
          message.timestamp,
          message.fileMetadata!.path!,
          message.fileMetadata!.mimeType!,
        );
      },
      extra: const PlayButton(),
    );
  }

  Widget _buildDownloadable() {
    if (message.fileMetadata!.thumbnailData != null) {
      final size = getMediaSize(message, maxWidth);

      return MediaBaseChatWidget(
        SizedBox(
          width: size.width,
          height: size.height,
          child: BlurHash(
            hash: message.fileMetadata!.thumbnailData!,
            decodingWidth: size.width.toInt(),
            decodingHeight: size.height.toInt(),
          ),
        ),
        MessageBubbleBottom(message, sent),
        radius,
        sent,
        message.senderJid,
        isGroupchat,
        extra: DownloadButton(
          onPressed: () => requestMediaDownload(message),
        ),
      );
    } else {
      return FileChatBaseWidget(
        message,
        message.fileMetadata!.filename,
        radius,
        maxWidth,
        sent,
        isGroupchat,
        mimeType: message.fileMetadata!.mimeType,
        downloadButton: DownloadButton(
          onPressed: () => requestMediaDownload(message),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (message.isUploading) {
      return _buildUploading();
    }
    if (message.isFileUploadNotification || message.isDownloading) {
      return _buildDownloading();
    }

    // TODO(PapaTutuWawa): Maybe use an async builder
    if (message.fileMetadata!.path != null &&
        File(message.fileMetadata!.path!).existsSync()) {
      return _buildVideo(context);
    }

    return _buildDownloadable();
  }
}
