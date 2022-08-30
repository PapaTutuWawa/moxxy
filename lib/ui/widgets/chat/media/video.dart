import 'dart:io';
import 'package:better_open_file/better_open_file.dart';
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
import 'package:moxxyv2/ui/widgets/chat/playbutton.dart';
import 'package:moxxyv2/ui/widgets/chat/progress.dart';
import 'package:moxxyv2/ui/widgets/chat/thumbnail.dart';

class VideoChatWidget extends StatelessWidget {

  const VideoChatWidget(
    this.message,
    this.radius,
    this.maxWidth,
    this.sent,
    {
      Key? key,
    }
  ) : super(key: key);
  final Message message;
  final double maxWidth;
  final BorderRadius radius;
  final bool sent;

  Widget _buildUploading() {
    return MediaBaseChatWidget(
      VideoThumbnailWidget(
        message.mediaUrl!,
        Image.memory,
      ),
      MessageBubbleBottom(message, sent),
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
        MessageBubbleBottom(message, sent),
        radius,
        extra: ProgressWidget(id: message.id),
      );
    } else {
      return FileChatBaseWidget(
        message,
        Icons.video_file_outlined,
        message.isFileUploadNotification ? (message.filename ?? '') : filenameFromUrl(message.srcUrl!),
        radius,
        sent,
        extra: ProgressWidget(id: message.id),
      );
    }
  }

  /// The video exists locally
  Widget _buildVideo() {
    return MediaBaseChatWidget(
      VideoThumbnailWidget(
        message.mediaUrl!,
        Image.memory,
      ),
      MessageBubbleBottom(message, sent),
      radius,
      onTap: () {
        OpenFile.open(message.mediaUrl);
      },
      extra: const PlayButton(),
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
        MessageBubbleBottom(message, sent),
        radius,
        extra: DownloadButton(
          onPressed: () => requestMediaDownload(message),
        ),
      );
    } else {
      return FileChatBaseWidget(
        message,
        Icons.video_file_outlined,
        message.isFileUploadNotification ? (message.filename ?? '') : filenameFromUrl(message.srcUrl!),
        radius,
        sent,
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
    if (message.isFileUploadNotification || message.isDownloading) return _buildDownloading();

    // TODO(PapaTutuWawa): Maybe use an async builder
    if (message.mediaUrl != null && File(message.mediaUrl!).existsSync()) return _buildVideo();

    return _buildDownloadable();
  }
}
