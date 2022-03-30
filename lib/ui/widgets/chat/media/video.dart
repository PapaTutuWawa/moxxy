import "dart:io";

import "package:moxxyv2/shared/models/message.dart";
import "package:moxxyv2/ui/widgets/chat/bottom.dart";
import "package:moxxyv2/ui/widgets/chat/blurhash.dart";
import "package:moxxyv2/ui/widgets/chat/playbutton.dart";
import "package:moxxyv2/ui/widgets/chat/helpers.dart";
//import "package:moxxyv2/ui/widgets/chat/media/image.dart";

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
    this.maxWidth,
    {
      required this.timestamp,
      required this.radius,
      Key? key
    }
  ) : super(key: key);

  @override
  // ignore: no_logic_in_create_state
  _VideoChatWidgetState createState() => _VideoChatWidgetState(
    message,
    maxWidth,
    timestamp: timestamp,
    radius: radius,
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
    {
      required this.timestamp,
      required this.radius,
    }
  ) : _thumbnailPath = "", _hasThumbnail = true;

  Future<String> _getThumbnailPath() async {
    final base = await ExternalPath.getExternalStoragePublicDirectory(ExternalPath.DIRECTORY_PICTURES);
    return pathlib.join(base, "Moxxy", ".thumbnail", message.conversationJid, pathlib.basename(message.mediaUrl!));
  }

  // TODO: Maybe create the thumbnail in another isolate
  Widget _showThumbnail() {
    if (_thumbnailPath.isNotEmpty && _hasThumbnail) {
      // TODO:
      /*
      return ImageChatWidget(
        path: _thumbnailPath,
        timestamp: timestamp,
        radius: radius,
        thumbnailData: thumbnailData,
        thumbnailSize: thumbnailSize,
        received: received,
        displayed: displayed,
        acked: acked,
        extra: const PlayButton()
      );
      */
      return const SizedBox();
    } else {
      if (!_hasThumbnail) {
        if (message.thumbnailData != null) {
          final thumbnailSize = getThumbnailSize(message, maxWidth);
          return BlurhashChatWidget(
            borderRadius: radius,
            width: thumbnailSize.width.toInt(),
            height: thumbnailSize.height.toInt(),
            thumbnailData: message.thumbnailData!,
            // TODO: Show download button
            child: const PlayButton()
          );
        } else {
          // TODO: Show download button
          return const Text("File not found");
        }
      } else {
        return const Padding(
          padding: EdgeInsets.only(top: 16.0, left: 16.0, right: 16.0, bottom: 32.0),
          child: CircularProgressIndicator()
        );
      }
    }
  }
  
  Future<void> _init() async {
    final path = message.mediaUrl!;
    final thumbnailPath = await _getThumbnailPath();
    if (await File(thumbnailPath).exists()) {
      setState(() {
          _thumbnailPath = thumbnailPath;
      });
    } else {
      final thumbnailDirPath = pathlib.dirname(thumbnailPath);
      final thumbnailDir = Directory(thumbnailDirPath);
      if (!(await thumbnailDir.exists())) {
        await thumbnailDir.create(recursive: true);
      }

      // Thumbnail not available
      if (await File(path).exists()) {
        // TODO: Generate thumbnail
        final f = await VideoCompress.getFileThumbnail(
          path,
          quality: 75
        );

        setState(() {
            _thumbnailPath = f.path;
        });
      } else {
        setState(() {
            _hasThumbnail = false;
        });
      }
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_thumbnailPath.isEmpty) {
      _init();
    }

    return IntrinsicWidth(
      child: InkWell(
        onTap: () {
          OpenFile.open(message.mediaUrl!);
        },
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: radius,
              child: _showThumbnail()
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
