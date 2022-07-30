import 'dart:math';

import 'package:flutter/material.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/widgets/chat/shared/base.dart';

class SharedSummaryWidget extends StatelessWidget {

  const SharedSummaryWidget(this.notShown, { Key? key }) : super(key: key);
  final int notShown;

  @override
  Widget build(BuildContext context) {
    final number = min(notShown, 99);
    return SharedMediaContainer(
      ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: ColoredBox(
          color: Colors.black38,
          child: Center(
            child: Text(
              '+$number',
              style: const TextStyle(
                fontSize: 30,
              ),
            ),
          ),
        ),
      ),
      onTap: () => Navigator.of(context).pushNamed(sharedMediaRoute),
    );
  }
}
