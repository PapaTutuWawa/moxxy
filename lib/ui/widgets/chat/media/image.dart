import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:moxplatform/moxplatform.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/ui/widgets/chat/bottom.dart';
import 'package:moxxyv2/ui/widgets/chat/downloadbutton.dart';
import 'package:moxxyv2/ui/widgets/chat/helpers.dart';
import 'package:moxxyv2/ui/widgets/chat/media/base.dart';
import 'package:moxxyv2/ui/widgets/chat/media/file.dart';
import 'package:moxxyv2/ui/widgets/chat/progress.dart';
import 'package:moxxyv2/ui/widgets/chat/thumbnail.dart';
import 'package:open_file/open_file.dart';

class ImageChatWidget extends StatelessWidget {

  const ImageChatWidget(
    this.message,
    this.radius,
    this.maxWidth,
    {
      Key? key,
    }
  ) : super(key: key);
  final Message message;
  final BorderRadius radius;
  final double maxWidth;

  Widget _buildUploading() {
    return MediaBaseChatWidget(
      ImageThumbnailWidget(
        message.mediaUrl!,
        Image.memory,
      ),
      MessageBubbleBottom(message),
      radius,
      extra: ProgressWidget(id: message.id),
    );
  }

  Widget _buildDownloading() {
    if (message.thumbnailData != null) {
      final thumbnailSize = getThumbnailSize(message, maxWidth);

      return MediaBaseChatWidget(
        SizedBox(
          width: thumbnailSize.width,
          height: thumbnailSize.height,
          child: BlurHash(
            hash: message.thumbnailData!,
            decodingWidth: thumbnailSize.width.toInt(),
            decodingHeight: thumbnailSize.height.toInt(),
          ),
        ),
        MessageBubbleBottom(message),
        radius,
        extra: ProgressWidget(id: message.id),
      );
    } else {
      return FileChatBaseWidget(
        message,
        Icons.image,
        filenameFromUrl(message.srcUrl!),
        radius,
        extra: ProgressWidget(id: message.id),
      );
    }
  }

  /// The image exists locally
  Widget _buildImage() {
    return MediaBaseChatWidget(
      ImageThumbnailWidget(
        message.mediaUrl!,
        Image.memory,
      ),
      MessageBubbleBottom(message),
      radius,
      onTap: () {
        OpenFile.open(message.mediaUrl);
      },
    );
  }

  Widget _buildDownloadable() {
    if (message.thumbnailData != null) {
      final thumbnailSize = getThumbnailSize(message, maxWidth);

      return MediaBaseChatWidget(
         SizedBox(
          width: thumbnailSize.width,
          height: thumbnailSize.height,
          child: BlurHash(
            hash: message.thumbnailData!,
            decodingWidth: thumbnailSize.width.toInt(),
            decodingHeight: thumbnailSize.height.toInt(),
          ),
        ),
        MessageBubbleBottom(message),
        radius,
        extra: DownloadButton(
          onPressed: () => requestMediaDownload(message),
        ),
      );
    } else {
      return FileChatBaseWidget(
        message,
        Icons.image,
        filenameFromUrl(message.srcUrl!),
        radius,
        extra: DownloadButton(
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
    if (message.isDownloading) return _buildDownloading();

    // TODO(PapaTutuWawa): Maybe use an async builder
    if (File(message.mediaUrl!).existsSync()) return _buildImage();

    return _buildDownloadable();
  }
}
