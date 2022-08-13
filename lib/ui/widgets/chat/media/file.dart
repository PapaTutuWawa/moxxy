import 'dart:core';

import 'package:flutter/material.dart';
import 'package:moxplatform/moxplatform.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/ui/widgets/chat/bottom.dart';
import 'package:moxxyv2/ui/widgets/chat/downloadbutton.dart';
import 'package:moxxyv2/ui/widgets/chat/media/image.dart';
import 'package:moxxyv2/ui/widgets/chat/progress.dart';
import 'package:open_file/open_file.dart';

/// Used whenever the mime type either doesn't match any specific chat widget or we just
/// cannot determine the mime type.
class FileChatWidget extends StatelessWidget {

  const FileChatWidget(
    this.message,
    {
      this.extra,
      Key? key,
    }
  ) : super(key: key);
  final Message message;
  final Widget? extra;

  Widget _buildNonDownloaded() {
    return ImageBaseChatWidget(
      Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.file_present,
              size: 128,
            ),

            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(filenameFromUrl(message.srcUrl!)),
            ),
          ],
        ),
      ),
      MessageBubbleBottom(message),
      BorderRadius.circular(8),
      gradient: false,
      extra: DownloadButton(
        onPressed: () {
          MoxplatformPlugin.handler.getDataSender().sendData(
            RequestDownloadCommand(message: message),
            awaitable: false,
          );
        },
      ),
    );
  }


  Widget _buildDownloading() {
    return ImageBaseChatWidget(
      Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.file_present,
              size: 128,
            ),

            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(filenameFromUrl(message.srcUrl!)),
            ),
          ],
        ),
      ),
      MessageBubbleBottom(message),
      BorderRadius.circular(8),
      gradient: false,
      extra: ProgressWidget(id: message.id),
    );
  }

  Widget _buildInner() {
    return ImageBaseChatWidget(
      Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.file_present,
              size: 128,
            ),

            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(filenameFromUrl(message.srcUrl!)),
            ),
          ],
        ),
      ),
      MessageBubbleBottom(message),
      BorderRadius.circular(8),
      gradient: false,
      onTap: () {
        OpenFile.open(message.mediaUrl);
      },
    );
  }

  Widget _buildWrapper() {
    if (!message.isDownloading && message.mediaUrl != null) return _buildInner();
    if (message.isDownloading) return _buildDownloading();

    return _buildNonDownloaded();
  }
  
  @override
  Widget build(BuildContext context) {
    return IntrinsicWidth(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: _buildWrapper(),
      ),
    );
  }
}
