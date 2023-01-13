import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:moxplatform/moxplatform.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/ui/widgets/chat/bottom.dart';
import 'package:moxxyv2/ui/widgets/chat/downloadbutton.dart';
import 'package:moxxyv2/ui/widgets/chat/helpers.dart';
import 'package:moxxyv2/ui/widgets/chat/media/base.dart';
import 'package:moxxyv2/ui/widgets/chat/media/file.dart';
import 'package:moxxyv2/ui/widgets/chat/progress.dart';

class ImageChatWidget extends StatelessWidget {
  const ImageChatWidget(
    this.message,
    this.radius,
    this.maxWidth,
    this.sent,
    {
      super.key,
    }
  );
  final Message message;
  final BorderRadius radius;
  final double maxWidth;
  final bool sent;

  Widget _buildUploading() {
    return MediaBaseChatWidget(
      Image.file(File(message.mediaUrl!)),
      MessageBubbleBottom(message, sent),
      radius,
      extra: ProgressWidget(id: message.id),
    );
  }

  Widget _buildDownloading() {
    if (message.thumbnailData != null) {
      final size = getMediaSize(message, maxWidth);

      return MediaBaseChatWidget(
        SizedBox(
          width: size.width,
          height: size.height,
          child: BlurHash(
            hash: message.thumbnailData!,
            decodingWidth: size.width.toInt(),
            decodingHeight: size.height.toInt(),
          ),
        ),
        MessageBubbleBottom(message, sent),
        radius,
        extra: ProgressWidget(id: message.id),
      );
    } else {
      return FileChatBaseWidget(
        message,
        message.isFileUploadNotification ?
          (message.filename ?? '') :
          filenameFromUrl(message.srcUrl!),
        radius,
        maxWidth,
        sent,
        mimeType: message.mediaType,
        downloadButton: ProgressWidget(id: message.id),
      );
    }
  }

  /// The image exists locally
  Widget _buildImage() {
    final size = getMediaSize(message, maxWidth);

    Widget image;
    if (message.mediaWidth != null && message.mediaHeight != null) {
      image = SizedBox(
        width: size.width,
        height: size.height,
        child: Image.file(File(message.mediaUrl!)),
      );
    } else {
      image = Image.file(File(message.mediaUrl!));
    }

    return MediaBaseChatWidget(
      image,
      MessageBubbleBottom(message, sent),
      radius,
      onTap: () => openFile(message.mediaUrl!),
    );
  }

  Widget _buildDownloadable() {
    if (message.thumbnailData != null) {
      final size = getMediaSize(message, maxWidth);

      return MediaBaseChatWidget(
         SizedBox(
          width: size.width,
          height: size.height,
          child: BlurHash(
            hash: message.thumbnailData!,
            decodingWidth: size.width.toInt(),
            decodingHeight: size.height.toInt(),
          ),
        ),
        MessageBubbleBottom(message, sent),
        radius,
        extra: DownloadButton(
          onPressed: () => requestMediaDownload(message),
        ),
      );
    } else {
      return FileChatBaseWidget(
        message,
        message.isFileUploadNotification ?
          (message.filename ?? '') :
          filenameFromUrl(message.srcUrl!),
        radius,
        maxWidth,
        sent,
        mimeType: message.mediaType,
        downloadButton: DownloadButton(
          onPressed: () {
            MoxplatformPlugin.handler.getDataSender().sendData(
              RequestDownloadCommand(message: message),
              awaitable: false,
            );
          },
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (message.isUploading) return _buildUploading();
    if (message.isFileUploadNotification || message.isDownloading) return _buildDownloading();

    // TODO(PapaTutuWawa): Maybe use an async builder
    if (message.mediaUrl != null && File(message.mediaUrl!).existsSync()) return _buildImage();

    return _buildDownloadable();
  }
}
