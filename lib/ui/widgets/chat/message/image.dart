import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/ui/widgets/chat/bottom.dart';
import 'package:moxxyv2/ui/widgets/chat/downloadbutton.dart';
import 'package:moxxyv2/ui/widgets/chat/helpers.dart';
import 'package:moxxyv2/ui/widgets/chat/message/base.dart';
import 'package:moxxyv2/ui/widgets/chat/message/file.dart';
import 'package:moxxyv2/ui/widgets/chat/progress.dart';
import 'package:moxxyv2/ui/widgets/chat/viewers/image.dart';

class ImageChatWidget extends StatelessWidget {
  const ImageChatWidget(
    this.message,
    this.radius,
    this.maxWidth,
    this.sent,
    this.isGroupchat, {
    super.key,
  });
  final Message message;
  final BorderRadius radius;
  final double maxWidth;
  final bool sent;
  final bool isGroupchat;

  Widget _buildUploading() {
    return MediaBaseChatWidget(
      Image.file(File(message.fileMetadata!.path!)),
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

  /// The image exists locally
  Widget _buildImage(BuildContext context) {
    final size = getMediaSize(message, maxWidth);

    Widget image;
    if (message.fileMetadata!.width != null &&
        message.fileMetadata!.height != null) {
      final density = MediaQuery.of(context).devicePixelRatio;
      image = SizedBox(
        width: size.width,
        height: size.height,
        child: Image.file(
          File(message.fileMetadata!.path!),
          cacheWidth: (size.width * density).toInt(),
          cacheHeight: (size.height * density).toInt(),
        ),
      );
    } else {
      // TODO(Unknown): Somehow have sensible defaults here
      image = Image.file(
        File(message.fileMetadata!.path!),
        // cacheWidth: size.width.toInt(),
        // cacheHeight: size.height.toInt(),
      );
    }

    return MediaBaseChatWidget(
      image,
      MessageBubbleBottom(
        message,
        sent,
      ),
      radius,
      sent,
      message.senderJid,
      isGroupchat,
      onTap: () {
        showImageViewer(
          context,
          message.timestamp,
          message.fileMetadata!.path!,
          message.fileMetadata!.mimeType!,
        );
      },
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
      return _buildImage(context);
    }

    return _buildDownloadable();
  }
}
