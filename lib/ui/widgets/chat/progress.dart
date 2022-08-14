import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/service/progress.dart';

// NOTE: Why do this? The reason is that if we did that in the [ChatBubble] widget, then
//       we would have to redraw the entire widget everytime the progress updates. If
//       we, for example, use blurhash, then we compute the image from the blurhash on every
//       update.

class ProgressWidget extends StatefulWidget {

  const ProgressWidget({ required this.id, Key? key }) : super(key: key);
  final int id;

  @override
  // ignore: no_logic_in_create_state
  ProgressWidgetState createState() => ProgressWidgetState(id: id);
}

class ProgressWidgetState extends State<ProgressWidget> {

  ProgressWidgetState({ required this.id }) : _progress = 0.0;
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
    GetIt.I.get<UIProgressService>().registerCallback(id, _onProgressUpdate);

    super.initState();
  }

  @override
  void dispose() {
    // Unregister
    GetIt.I.get<UIProgressService>().unregisterCallback(id);

    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(100),
        color: backdropBlack,
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: CircularProgressIndicator(value: _progress),
      ),
    );
  }
}
