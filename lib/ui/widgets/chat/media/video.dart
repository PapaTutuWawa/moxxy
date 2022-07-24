import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/ui/widgets/chat/bottom.dart';
import 'package:moxxyv2/ui/widgets/chat/downloadbutton.dart';
import 'package:moxxyv2/ui/widgets/chat/helpers.dart';
import 'package:moxxyv2/ui/widgets/chat/media/file.dart';
import 'package:moxxyv2/ui/widgets/chat/media/image.dart';
import 'package:moxxyv2/ui/widgets/chat/playbutton.dart';
import 'package:moxxyv2/ui/widgets/chat/progress.dart';
import 'package:moxxyv2/ui/widgets/chat/thumbnail.dart';
import 'package:open_file/open_file.dart';

class VideoChatWidget extends StatelessWidget {

  const VideoChatWidget(
    this.message,
    this.radius,
    this.maxWidth,
    {
      Key? key,
    }
  ) : super(key: key);
  final Message message;
  final double maxWidth;
  final BorderRadius radius;

  Widget _buildUploading() {
    return ImageBaseChatWidget(
      VideoThumbnailWidget(
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

      return ImageBaseChatWidget(
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
      // TODO(PapaTutuWawa): Do we need to set the ProgressWidget here?
      return FileChatWidget(message);
    }
  }

  /// The video exists locally
  Widget _buildVideo() {
    return ImageBaseChatWidget(
      VideoThumbnailWidget(
        message.mediaUrl!,
        Image.memory,
      ),
      MessageBubbleBottom(message),
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

      return ImageBaseChatWidget(
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
      return FileChatWidget(
        message,
        extra: ElevatedButton(
          onPressed: () => requestMediaDownload(message),
          child: const Text('Download'),
        ),
      );
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (message.isUploading) return _buildUploading();
    if (message.isDownloading) return _buildDownloading();

    // TODO(PapaTutuWawa): Maybe use an async builder
    if (File(message.mediaUrl!).existsSync()) return _buildVideo();

    return _buildDownloadable();
  }
}
