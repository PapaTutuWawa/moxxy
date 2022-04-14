import "dart:math";

import "package:moxxyv2/ui/constants.dart";
import "package:moxxyv2/ui/widgets/chat/shared/base.dart";

import "package:flutter/material.dart";

class SharedSummaryWidget extends StatelessWidget {
  final int notShown;

  const SharedSummaryWidget(this.notShown, { Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final number = min(notShown, 99);
    return SharedMediaContainer(
      ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black38
          ),
          child: Center(
            child: Text(
              "+$notShown",
              style: TextStyle(
                fontSize: 30
              )
            )
          )
        )
      ),
      onTap: () => Navigator.of(context).pushNamed(sharedMediaRoute)
    );
  }
}
