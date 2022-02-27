import "package:moxxyv2/ui/service/download.dart";

import "package:flutter/material.dart";
import "package:get_it/get_it.dart";

// NOTE: Why do this? The reason is that if we did that in the [ChatBubble] widget, then
//       we would have to redraw the entire widget everytime the progress updates. If
//       we, for example, use blurhash, then we compute the image from the blurhash on every
//       update.

class DownloadProgress extends StatefulWidget {
  final int id;

  const DownloadProgress({ required this.id, Key? key }) : super(key: key);

  @override
  // ignore: no_logic_in_create_state
  _DownloadProgressState createState() => _DownloadProgressState(id: id);
}

class _DownloadProgressState extends State<DownloadProgress> {
  final int id;

  double _progress;

  _DownloadProgressState({ required this.id }) : _progress = 0.0;

  void _onProgressUpdate(double progress) {
    setState(() {
        _progress = progress;
    });
  }
  
  @override
  void initState() {
    // Register against the DownloadService
    GetIt.I.get<UIDownloadService>().registerCallback(id, _onProgressUpdate);

    super.initState();
  }

  @override
  void dispose() {
    // Unregister
    GetIt.I.get<UIDownloadService>().unregisterCallback(id);

    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return CircularProgressIndicator(value: _progress);
  }
}
