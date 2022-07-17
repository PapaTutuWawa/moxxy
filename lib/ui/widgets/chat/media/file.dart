import 'dart:core';

import 'package:flutter/material.dart';
import 'package:moxplatform/moxplatform.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/ui/widgets/chat/bottom.dart';
import 'package:moxxyv2/ui/widgets/chat/download.dart';
import 'package:path/path.dart' as pathlib;

class _FileChatBaseWidget extends StatelessWidget {

  const _FileChatBaseWidget(
    this.url,
    this.filename,
    this.bottom,
    {
      this.extra,
      this.progress,
      this.showIcon = true,
    }
  );
  final String url;
  final String filename;
  final MessageBubbleBottom bottom;
  final bool showIcon;

  final Widget? extra;
  final DownloadProgress? progress;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: IntrinsicHeight(
            child: Stack(
              children: [
                ...showIcon ? [
                    const Icon(
                      Icons.file_present,
                      size: 128,
                    )
                  ] : [],
                ...progress != null ?
                  [
                    Positioned.fill(
                      child: Align(
                        child: SizedBox(
                          width: 64,
                          height: 64,
                          child: progress,
                        ),
                      ),
                    )
                  ] : []
              ],
            ),
          ),
        ),
        Text(
          filename,
        ),

        // e.g. download button
        ...extra != null ? [ extra! ] : [],

        // The bottom bar
        bottom
      ],
    );
  }
}

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
    return _FileChatBaseWidget(
      message.srcUrl!,
      filenameFromUrl(message.srcUrl!),
      MessageBubbleBottom(message),
      extra: ElevatedButton(
        onPressed: () {
          MoxplatformPlugin.handler.getDataSender().sendData(
            RequestDownloadCommand(message: message),
            awaitable: false,
          );
        },
        child: const Text('Download'),
      ),
    );
  }


  Widget _buildDownloading() {
    return _FileChatBaseWidget(
      message.srcUrl!,
      filenameFromUrl(message.srcUrl!),
      MessageBubbleBottom(message),
      progress: DownloadProgress(id: message.id),
      showIcon: false,
    );
  }

  Widget _buildInner() {
    final filename = pathlib.basename(message.mediaUrl!);

    // TODO(Unknown): Make clickable
    return _FileChatBaseWidget(
      message.srcUrl!,
      filename,
      MessageBubbleBottom(message),
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
