import "dart:io";

import "package:moxxyv2/ui/widgets/chat/bottom.dart";
import "package:moxxyv2/ui/widgets/chat/filenotfound.dart";
import "package:moxxyv2/ui/widgets/chat/file.dart";
import "package:moxxyv2/ui/widgets/chat/blurhash.dart";

import "package:flutter/material.dart";
import "package:path/path.dart" as pathlib;
import "package:open_file/open_file.dart";

class ImageChatWidget extends StatelessWidget {
  final String path;
  final String timestamp;
  final BorderRadius radius;
  final String? thumbnailData;
  final Size thumbnailSize;
  final bool received;
  final bool displayed;
  final Widget? extra;

  const ImageChatWidget({
      required this.path,
      required this.timestamp,
      required this.radius,
      required this.thumbnailSize,
      required this.received,
      required this.displayed,
      this.extra,
      this.thumbnailData,
      Key? key
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: InkResponse(
        onTap: () {
          OpenFile.open(path);
        },
        child: Stack(
          alignment: Alignment.center,
          children: [
            ClipRRect(
              borderRadius: radius,
              child: Image.file(
                File(path),
                errorBuilder: (context, error, trace) {
                  if (thumbnailData != null) {
                    return BlurhashChatWidget(
                      width: thumbnailSize.width.toInt(),
                      height: thumbnailSize.height.toInt(),
                      borderRadius: radius,
                      thumbnailData: thumbnailData!,
                      child: const FileNotFound()
                    );
                  } else {
                    return FileChatWidget(
                      path: path,
                      filename: pathlib.basename(path),
                      timestamp: timestamp,
                      received: received,
                      displayed: displayed,
                      extra: const FileNotFound()
                    );
                  }
                }
              )
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
            ...(extra != null ? [ extra! ] : []),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 3.0, right: 6.0),
                child: MessageBubbleBottom(timestamp: timestamp, received: received, displayed: displayed)
              )
            ) 
          ]
        )
      )
    );
  }
}
