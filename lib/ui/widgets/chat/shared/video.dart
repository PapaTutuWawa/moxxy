import "dart:typed_data";
import "dart:async";

import "package:moxxyv2/ui/service/thumbnail.dart";
import "package:moxxyv2/ui/widgets/chat/playbutton.dart";
import "package:moxxyv2/ui/widgets/chat/shared/base.dart";

import "package:flutter/material.dart";
import "package:get_it/get_it.dart";
import "package:path/path.dart" as pathlib;

class SharedVideoWidget extends StatelessWidget {
  final String path;
  final String jid;

  const SharedVideoWidget(this.path, this.jid, { Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SharedMediaContainer(
      ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            FutureBuilder<Uint8List>(
              future: GetIt.I.get<ThumbnailCacheService>().getVideoThumbnail(path),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.data != null) {
                    return Image.memory(
                      snapshot.data!,
                      fit: BoxFit.cover
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
                  return const CircularProgressIndicator();
                }
              }
            ),
            const PlayButton(size: 16.0)
          ]
        )
      )
    );
  }
}
