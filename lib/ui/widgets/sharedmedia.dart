import "package:moxxyv2/ui/widgets/sharedimage.dart";

import "package:flutter/material.dart";

class SharedMediaDisplay extends StatelessWidget {
  final List<String> sharedMediaPaths;

  const SharedMediaDisplay({ required this.sharedMediaPaths, Key? key }) : super(key: key);

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
    int clampedEnd = sharedMediaPaths.length >= 8 ? 8 : sharedMediaPaths.length;
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 25.0),
          child: Text(
            "Shared Media",
            style: TextStyle(
              fontSize: 25
            )
          )
        ),
        Padding(
          padding: const EdgeInsets.only(top: 8.0),
          child: Container(
            alignment: Alignment.topLeft,
            child: Wrap(
              spacing: 5,
              runSpacing: 5,
              children: sharedMediaPaths.getRange(0, clampedEnd).map((item) => _renderSharedItem(item)).toList()
            )
          )
        )
      ]
    );
  }
}
