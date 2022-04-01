import "dart:io";

import "package:moxxyv2/shared/models/message.dart";
import "package:moxxyv2/ui/service/data.dart";
import "package:moxxyv2/ui/widgets/chat/bottom.dart";
import "package:moxxyv2/ui/widgets/chat/blurhash.dart";
import "package:moxxyv2/ui/widgets/chat/playbutton.dart";
import "package:moxxyv2/ui/widgets/chat/helpers.dart";
import "package:moxxyv2/ui/widgets/chat/media/image.dart";
import "package:moxxyv2/ui/widgets/chat/media/file.dart";

import "package:flutter/material.dart";
import "package:path/path.dart" as pathlib;
import "package:get_it/get_it.dart";
import "package:video_compress/video_compress.dart";
import "package:open_file/open_file.dart";

class VideoChatWidget extends StatefulWidget {
  final String timestamp;
  final Message message;
  final double maxWidth;
  final BorderRadius radius;

  const VideoChatWidget(
    this.message,
    this.timestamp,
    this.radius,
    this.maxWidth,
    {
      Key? key
    }
  ) : super(key: key);

  // ignore: no_logic_in_create_state
  @override
  _VideoChatWidgetState createState() => _VideoChatWidgetState(
    message,
    maxWidth,
    timestamp,
    radius,
  );
}

class _VideoChatWidgetState extends State<VideoChatWidget> {
  final String timestamp;
  final BorderRadius radius;
  final double maxWidth;
  final Message message;

  _VideoChatWidgetState(
    this.message,
    this.maxWidth,
    this.timestamp,
    this.radius,
  );

  /// Returns the path of a possible thumbnail for the video. Does not imply that the file
  /// exists.
  String _getThumbnailPath() {
    final base = GetIt.I.get<UIDataService>().thumbnailBase;
    return pathlib.join(base, message.conversationJid, pathlib.basename(message.mediaUrl!));
  }

  /// Generate the thumbnail if needed.
  Future<bool> _thumbnailFuture() async {
    final thumbnailFile = File(_getThumbnailPath());
    if (await thumbnailFile.exists()) {
      return true;
    }

    // Thumbnail does not exist
    final sourceFile = File(message.mediaUrl!);
    if (await sourceFile.exists()) {
      final bytes = await VideoCompress.getByteThumbnail(
        sourceFile.path,
        quality: 75
      );
      await thumbnailFile.writeAsBytes(bytes!);

      return true;
    }

    // Source file also does not exist. Return "error".
    return false;
  }
  
  Widget _buildNonDownloaded() {
    // TODO
    if (message.thumbnailData != null) {}

    return FileChatWidget(
      message,
      timestamp,
      extra: ElevatedButton(
        // TODO
        onPressed: () {},
        child: const Text("Download")
      )
    );
  }

  Widget _buildDownloading() {
    // TODO
    if (message.thumbnailData != null) {}

    return FileChatWidget(
      message,
      timestamp,
    );
  }

  Widget _buildVideo() {
    return FutureBuilder<bool>(
      future: _thumbnailFuture(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          if (snapshot.data!) {
            return ImageBaseChatWidget(
              message.mediaUrl!,
              radius,
              Image.file(File(_getThumbnailPath())),
              MessageBubbleBottom(
                message,
                timestamp: timestamp,
              ),
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
            Positioned(
              bottom: 0,
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                alignment: Alignment.bottomCenter,
                decoration: BoxDecoration(
                  borderRadius: radius,
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withAlpha(0),
                      Colors.black12,
                      Colors.black54
                    ]
                  )
                )
              )
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 3.0, right: 6.0),
                child: MessageBubbleBottom(
                  message,
                  timestamp: timestamp
                )
              )
            ) 
          ]
        )
      )
    );
  }
}
