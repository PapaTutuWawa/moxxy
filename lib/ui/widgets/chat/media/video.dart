import "dart:io";

import "package:moxxyv2/shared/models/message.dart";
import "package:moxxyv2/ui/widgets/chat/bottom.dart";
import "package:moxxyv2/ui/widgets/chat/blurhash.dart";
import "package:moxxyv2/ui/widgets/chat/playbutton.dart";
import "package:moxxyv2/ui/widgets/chat/helpers.dart";
import "package:moxxyv2/ui/widgets/chat/media/image.dart";

import "package:flutter/material.dart";
import "package:path/path.dart" as pathlib;
import "package:external_path/external_path.dart";
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

  String _thumbnailPath;
  bool _hasThumbnail;

  _VideoChatWidgetState(
    this.message,
    this.maxWidth,
    this.timestamp,
    this.radius,
  ) : _thumbnailPath = "", _hasThumbnail = true;

  Future<String> _getThumbnailPath() async {
    final base = await ExternalPath.getExternalStoragePublicDirectory(ExternalPath.DIRECTORY_PICTURES);
    return pathlib.join(base, "Moxxy", ".thumbnail", message.conversationJid, pathlib.basename(message.mediaUrl!));
  }

  Widget _buildNonDownloaded() {
    // TODO
    return const SizedBox();
  }

  Widget _buildDownloading() {
    // TODO
    return const SizedBox();
  }

  Widget _buildVideo() {
    return ImageBaseChatWidget(
      message.mediaUrl!,
      radius,
      Image.file(File(message.mediaUrl!)),
      MessageBubbleBottom(
        message,
        timestamp: timestamp,
      ),
      extra: const PlayButton()
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
