import 'dart:math';
import 'package:flutter/material.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/pages/sharedmedia.dart';
import 'package:moxxyv2/ui/widgets/chat/shared/base.dart';

class SharedSummaryWidget extends StatelessWidget {
  const SharedSummaryWidget({
    required this.notShown,
    required this.conversationJid,
    required this.conversationTitle,
    super.key,
  });
  final int notShown;
  final String conversationJid;
  final String conversationTitle;

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
      onTap: () => Navigator.of(context).pushNamed(
        sharedMediaRoute,
        arguments: SharedMediaPageArguments(
          conversationJid,
          conversationTitle,
        ),
      ),
    );
  }
}
