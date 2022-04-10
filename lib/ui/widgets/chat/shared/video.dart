import "dart:io";

import "package:moxxyv2/ui/service/data.dart";
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
    final filename = pathlib.basename(path);
    final thumbnail = GetIt.I.get<UIDataService>().getThumbnailPathFull(jid, filename);

    // TODO: Error handling
    return SharedMediaContainer(
      ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.file(
              File(thumbnail), fit: BoxFit.cover
            ),
            const PlayButton(size: 16.0)
          ]
        )
      )
    );
  }
}
