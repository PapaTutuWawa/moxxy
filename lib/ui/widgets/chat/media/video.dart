import "dart:io";

import "package:moxxyv2/shared/models/message.dart";
import "package:moxxyv2/ui/service/data.dart";
import "package:moxxyv2/ui/widgets/chat/gradient.dart";
import "package:moxxyv2/ui/widgets/chat/bottom.dart";
import "package:moxxyv2/ui/widgets/chat/playbutton.dart";
import "package:moxxyv2/ui/widgets/chat/helpers.dart";
import "package:moxxyv2/ui/widgets/chat/media/image.dart";
import "package:moxxyv2/ui/widgets/chat/media/file.dart";

import "package:flutter/material.dart";
import "package:get_it/get_it.dart";
import "package:video_compress/video_compress.dart";
import "package:open_file/open_file.dart";

class VideoChatWidget extends StatefulWidget {
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

  @override
  _VideoChatWidgetState createState() => _VideoChatWidgetState();
}

class _VideoChatWidgetState extends State<VideoChatWidget> {
  /// Generate the thumbnail if needed.
  Future<bool> _thumbnailFuture() async {
    final thumbnail = GetIt.I.get<UIDataService>().getThumbnailPath(widget.message);
    final thumbnailFile = File(thumbnail);
    if (await thumbnailFile.exists()) {
      return true;
    }

    // Thumbnail does not exist
    final sourceFile = File(widget.message.mediaUrl!);
    if (await sourceFile.exists()) {
      final bytes = await VideoCompress.getByteThumbnail(
        sourceFile.path,
        quality: 75
      );
      if (bytes == null) return false;
      await thumbnailFile.writeAsBytes(bytes);

      return true;
    }

    // Source file also does not exist. Return "error".
    return false;
  }
  
  Widget _buildNonDownloaded() {
    // TODO
    if (widget.message.thumbnailData != null) {}

    return FileChatWidget(
      widget.message,
      extra: ElevatedButton(
        onPressed: () => requestMediaDownload(widget.message),
        child: const Text("Download")
      )
    );
  }

  Widget _buildDownloading() {
    // TODO
    if (widget.message.thumbnailData != null) {}

    return FileChatWidget(widget.message);
  }

  Widget _buildVideo() {
    return FutureBuilder<bool>(
      future: _thumbnailFuture(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.data!) {
            final thumbnail = GetIt.I.get<UIDataService>().getThumbnailPath(widget.message);
            return ImageBaseChatWidget(
              widget.message.mediaUrl!,
              widget.radius,
              Image.file(File(thumbnail)),
              MessageBubbleBottom(widget.message),
              extra: const PlayButton()
            );
          } else {
            // TODO: Error
            return const Text("Error");
          }
        } else {
          return const CircularProgressIndicator();
        }
      }
    );
  }

  Widget _innerBuild() {
    final message = widget.message;
    if (!message.isDownloading && message.mediaUrl != null) return _buildVideo();
    if (message.isDownloading) return _buildDownloading();

    return _buildNonDownloaded();
  }
  
  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: InkWell(
        onTap: () {
          OpenFile.open(widget.message.mediaUrl!);
        },
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: widget.radius,
              child: _innerBuild()
            ),
            BottomGradient(widget.radius),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 3.0, right: 6.0),
                child: MessageBubbleBottom(widget.message)
              )
            ) 
          ]
        )
      )
    );
  }
}
