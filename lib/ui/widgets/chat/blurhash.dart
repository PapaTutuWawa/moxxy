import "dart:typed_data";

import "package:moxxyv2/ui/widgets/chat/download.dart";

import "package:flutter/material.dart";
import "package:blurhash/blurhash.dart";

class BlurhashChatWidget extends StatelessWidget {
  final BorderRadius borderRadius;
  final int id;
  final int width;
  final int height;
  final String thumbnailData;

  const BlurhashChatWidget({ required this.borderRadius, required this.id, required this.width, required this.height, required this.thumbnailData, Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List?>(
      future: (() async {
          try {
            return await BlurHash.decode(thumbnailData, width, height);
          } on Exception catch(e) {
            // TODO: Use logging
            print(e.toString());
          }

          return null;
      })(),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return IntrinsicWidth(
            child: Stack(
              alignment: Alignment.center,
              children: [
                ClipRRect(
                  borderRadius: borderRadius,
                  child: Image.memory(snapshot.data!)
                ),
                DownloadProgress(id: id)
              ]
            )
          );
        }

        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: DownloadProgress(id: id)
        );
      }
    );
  }
}
