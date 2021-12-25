import 'package:flutter/material.dart';
import 'package:moxxyv2/ui/widgets/sharedimage.dart';

class SharedMediaDisplay extends StatelessWidget {
  final List<String> sharedMediaPaths;

  SharedMediaDisplay({ required this.sharedMediaPaths });

  Widget _renderSharedItem(String item) {
    return SharedMediaContainer(
      // TODO
      image: NetworkImage(
        item
      )
    );
  }
  
  @override
  Widget build(BuildContext context) {
    int clampedEnd = this.sharedMediaPaths.length >= 8 ? 8 : this.sharedMediaPaths.length;
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.only(top: 25.0),
          child: Text(
            "Shared Media",
            style: TextStyle(
              fontSize: 25
            )
          )
        ),
        Padding(
          padding: EdgeInsets.only(top: 8.0),
          child: Container(
            alignment: Alignment.topLeft,
            child: Wrap(
              spacing: 5,
              runSpacing: 5,
              children: this.sharedMediaPaths.getRange(0, clampedEnd).map((item) => this._renderSharedItem(item)).toList()
            )
          )
        )
      ]
    );
  }
}
