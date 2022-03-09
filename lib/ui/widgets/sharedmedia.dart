import "dart:io";
import "dart:math";

import "package:moxxyv2/ui/widgets/sharedimage.dart";

import "package:flutter/material.dart";
import "package:open_file/open_file.dart";

class SharedMediaDisplay extends StatelessWidget {
  final List<String> sharedMediaPaths;

  const SharedMediaDisplay({ required this.sharedMediaPaths, Key? key }) : super(key: key);

  Widget _renderSharedItem(String item) {
    return SharedMediaContainer(
      image: FileImage(File(item)),
      onTap: () => OpenFile.open(item)
    );
  }

  List<Widget> _renderItems() {
    int clampedStartIndex = sharedMediaPaths.length > 8 ? sharedMediaPaths.length - 9 : 0;
    int clampedEndIndex = min(clampedStartIndex + 8, sharedMediaPaths.length) - 1;
    final tmp = List<Widget>.empty(growable: true);

    for (var i = clampedEndIndex; i >= clampedStartIndex; i--) {
      print(i);
      tmp.add(_renderSharedItem(sharedMediaPaths[i]));
    }

    return tmp;
  }
  
  @override
  Widget build(BuildContext context) {
    if (sharedMediaPaths.isEmpty) return const SizedBox();

    final width = MediaQuery.of(context).size.width;
    // NOTE: Based on the formula width = 2padding + (n-1)5 + 75n,
    //       with n being the number of item to show. If we set n=4, then
    //       the padding will always be the same.
    final padding = 0.5 * (width - 15 - 300);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
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
          padding: EdgeInsets.only(top: 8.0, left: padding, right: padding),
          child: Container(
            alignment: Alignment.topLeft,
            child: Wrap(
              spacing: 5,
              runSpacing: 5,
              children: _renderItems()
            )
          )
        )
      ]
    );
  }
}
