import "dart:typed_data";

import "package:moxxyv2/shared/models/message.dart";
import "package:moxxyv2/ui/service/thumbnail.dart";
import "package:moxxyv2/ui/widgets/chat/gradient.dart";
import "package:moxxyv2/ui/widgets/chat/bottom.dart";
import "package:moxxyv2/ui/widgets/chat/playbutton.dart";
import "package:moxxyv2/ui/widgets/chat/helpers.dart";
import "package:moxxyv2/ui/widgets/chat/media/image.dart";
import "package:moxxyv2/ui/widgets/chat/media/file.dart";

import "package:flutter/material.dart";
import "package:get_it/get_it.dart";
import "package:open_file/open_file.dart";

class VideoChatWidget extends StatelessWidget {
  final Message message;
  final double maxWidth;
  final BorderRadius radius;

  const VideoChatWidget(
    this.message,
    this.radius,
    this.maxWidth,
    {
      Key? key
    }
  ) : super(key: key);

  Widget _buildNonDownloaded() {
    // TODO
    if (message.thumbnailData != null) {}

    return FileChatWidget(
      message,
      extra: ElevatedButton(
        onPressed: () => requestMediaDownload(message),
        child: const Text("Download")
      )
    );
  }

  Widget _buildDownloading() {
    // TODO
    if (message.thumbnailData != null) {}

    return FileChatWidget(message);
  }

  Widget _buildVideo() {
    return FutureBuilder<Uint8List>(
      future: GetIt.I.get<ThumbnailCacheService>().getVideoThumbnail(message.mediaUrl!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.data != null) {
            return ImageBaseChatWidget(
              message.mediaUrl!,
              radius,
              Image.memory(snapshot.data!),
              MessageBubbleBottom(message),
              extra: const PlayButton()
            );
          } else {
            return const Padding(
              padding: EdgeInsets.all(32.0),
              child: Icon(
                Icons.error_outline,
                size: 32.0
              )
            );
          }
        } else {
          return const Padding(
            padding: EdgeInsets.all(32.0),
            child: CircularProgressIndicator()
          );
        }
      }
    );
  }

  Widget _innerBuild() {
    if (!message.isDownloading && message.mediaUrl != null) return _buildVideo();
    if (message.isDownloading) return _buildDownloading();

    return _buildNonDownloaded();
  }
  
  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: InkWell(
        onTap: () {
          OpenFile.open(message.mediaUrl!);
        },
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: radius,
              child: _innerBuild()
            ),
            BottomGradient(radius),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 3.0, right: 6.0),
                child: MessageBubbleBottom(message)
              )
            ) 
          ]
        )
      )
    );
  }
}
