import "package:moxxyv2/ui/widgets/chat/bottom.dart";

import "package:flutter/material.dart";

/// Used whenever the mime type either doesn't match any specific chat widget or we just
/// cannot determine the mime type.
class FileChatWidget extends StatelessWidget {
  final String filename;
  final String path;
  final String timestamp;

  const FileChatWidget({ required this.filename, required this.path, required this.timestamp, Key? key }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // TODO: Click handler
    return IntrinsicWidth(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 8.0),
              child: Icon(
                Icons.file_present,
                size: 128.0
              )
            ),
            Text(
              filename
            ),
            MessageBubbleBottom(timestamp: timestamp)
          ]
        )
      )
    );
  }
}
