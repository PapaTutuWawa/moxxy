import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_blurhash/flutter_blurhash.dart';
//import 'package:get_it/get_it.dart';
import 'package:moxxyv2/shared/models/message.dart';
//import 'package:moxxyv2/ui/service/thumbnail.dart';
import 'package:moxxyv2/ui/widgets/chat/bottom.dart';
import 'package:moxxyv2/ui/widgets/chat/downloadbutton.dart';
//import 'package:moxxyv2/ui/widgets/chat/filenotfound.dart';
import 'package:moxxyv2/ui/widgets/chat/gradient.dart';
import 'package:moxxyv2/ui/widgets/chat/helpers.dart';
import 'package:moxxyv2/ui/widgets/chat/media/file.dart';
import 'package:moxxyv2/ui/widgets/chat/progress.dart';
import 'package:open_file/open_file.dart';

/// A base container allowing to embed a child in a borderless ChatBubble. If onTap is
/// set, then it will be called as soon as the bubble is tapped. If extra is set, then
/// it will be put on top of the bubble in the center.
class ImageBaseChatWidget extends StatelessWidget {

  const ImageBaseChatWidget(
    this.background,
    this.bottom,
    this.radius,
    {
      this.onTap,
      this.extra,
      Key? key,
    }
  ) : super(key: key);
  final Widget background;
  final Widget? extra;
  final MessageBubbleBottom bottom;
  final BorderRadius radius;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: InkResponse(
        onTap: onTap,
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: radius,
              child: background,
            ),
            BottomGradient(radius),
            ...extra != null ? [ extra! ] : [],
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 3, right: 6),
                child: bottom,
              ),
            ) 
          ],
        ),
      ),
    );
  }
}

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
    return ImageBaseChatWidget(
      // TODO(PapaTutuWawa): Use the thumbnail service
      Image.file(File(message.mediaUrl!)),
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

  /// The image exists locally
  Widget _buildImage() {
    return ImageBaseChatWidget(
      // TODO(PapaTutuWawa): Use the thumbnail service
      Image.file(File(message.mediaUrl!)),
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
    if (File(message.mediaUrl!).existsSync()) return _buildImage();

    return _buildDownloadable();
  }
}
