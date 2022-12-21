import 'dart:math';
import 'package:flutter/material.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/widgets/chat/shared/base.dart';

class SharedSummaryWidget extends StatelessWidget {
  const SharedSummaryWidget(this.notShown, { super.key });
  final int notShown;

  @override
  Widget build(BuildContext context) {
    final number = min(notShown, 99);
    return SharedMediaContainer(
      Center(
        child: Text(
          '+$number',
          style: const TextStyle(
            fontSize: 30,
          ),
        ),
      ),
      color: sharedMediaSummaryBackgroundColor,
      onTap: () => Navigator.of(context).pushNamed(sharedMediaRoute),
    );
  }
}
