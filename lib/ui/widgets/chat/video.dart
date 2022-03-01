import "dart:io";

import "package:moxxyv2/ui/widgets/chat/bottom.dart";
import "package:moxxyv2/ui/widgets/chat/blurhash.dart";
import "package:moxxyv2/ui/widgets/chat/image.dart";
import "package:moxxyv2/ui/widgets/chat/playbutton.dart";

import "package:flutter/material.dart";
import "package:path/path.dart" as pathlib;
import "package:external_path/external_path.dart";
import "package:video_compress/video_compress.dart";

class VideoChatWidget extends StatefulWidget {
  final String path;
  final String timestamp;
  final String conversationJid;
  final BorderRadius radius;
  final String? thumbnailData;
  final Size thumbnailSize;

  const VideoChatWidget({ required this.path, required this.timestamp, required this.radius, this.thumbnailData, required this.thumbnailSize, required this.conversationJid });

  @override
  _VideoChatWidgetState createState() => _VideoChatWidgetState(
    path: path,
    timestamp: timestamp,
    conversationJid: conversationJid,
    radius: radius,
    thumbnailData: thumbnailData,
    thumbnailSize: thumbnailSize
  );
}

class _VideoChatWidgetState extends State<VideoChatWidget> {
  final String path;
  final String timestamp;
  final String conversationJid;
  final BorderRadius radius;
  final String? thumbnailData;
  final Size thumbnailSize;

  String _thumbnailPath;
  bool _hasThumbnail;

  _VideoChatWidgetState({ required this.path, required this.timestamp, required this.radius, this.thumbnailData, required this.thumbnailSize, required this.conversationJid }) : _thumbnailPath = "", _hasThumbnail = true;

  Future<String> _getThumbnailPath() async {
    final base = await ExternalPath.getExternalStoragePublicDirectory(ExternalPath.DIRECTORY_PICTURES);
    return pathlib.join(base, "Moxxy", ".thumbnail", conversationJid, pathlib.basename(path));
  }

  // TODO: Maybe create the thumbnail in another isolate
  Widget _showThumbnail() {
    if (_thumbnailPath.isNotEmpty && _hasThumbnail) {
      return ImageChatWidget(
        path: _thumbnailPath,
        timestamp: timestamp,
        radius: radius,
        thumbnailData: thumbnailData,
        thumbnailSize: thumbnailSize,
        extra: PlayButton()
      );
    } else {
      if (!_hasThumbnail) {
        if (thumbnailData != null) {
          return BlurhashChatWidget(
            borderRadius: radius,
            width: thumbnailSize.width.toInt(),
            height: thumbnailSize.height.toInt(),
            thumbnailData: thumbnailData!,
            // TODO: Show download button
            child: PlayButton()
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

    return IntrinsicWidth(child: Stack(
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
              child: MessageBubbleBottom(timestamp: timestamp)
            )
          ) 
        ]
    ));
  }
}
