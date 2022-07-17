import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxyv2/ui/service/download.dart';

// NOTE: Why do this? The reason is that if we did that in the [ChatBubble] widget, then
//       we would have to redraw the entire widget everytime the progress updates. If
//       we, for example, use blurhash, then we compute the image from the blurhash on every
//       update.

class DownloadProgress extends StatefulWidget {

  const DownloadProgress({ required this.id, Key? key }) : super(key: key);
  final int id;

  @override
  // ignore: no_logic_in_create_state
  DownloadProgressState createState() => DownloadProgressState(id: id);
}

class DownloadProgressState extends State<DownloadProgress> {

  DownloadProgressState({ required this.id }) : _progress = 0.0;
  final int id;

  double _progress;

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
