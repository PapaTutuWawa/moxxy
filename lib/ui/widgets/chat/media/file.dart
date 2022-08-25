import 'dart:core';

import 'package:flutter/material.dart';
import 'package:moxplatform/moxplatform.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/ui/widgets/chat/bottom.dart';
import 'package:moxxyv2/ui/widgets/chat/downloadbutton.dart';
import 'package:moxxyv2/ui/widgets/chat/media/base.dart';
import 'package:moxxyv2/ui/widgets/chat/progress.dart';
import 'package:open_file/open_file.dart';

/// A base widget for sent/received files that cannot be displayed otherwise.
class FileChatBaseWidget extends StatelessWidget {
  const FileChatBaseWidget(
    this.message,
    this.icon,
    this.filename,
    this.radius,
    this.sent,
    {
      this.extra,
      this.onTap,
      Key? key,
    }
  ) : super(key: key);
  final Message message;
  final IconData icon;
  final String filename;
  final BorderRadius radius;
  final Widget? extra;
  final bool sent;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return MediaBaseChatWidget(
      Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 128,
            ),

            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(filename),
            ),
          ],
        ),
      ),
      MessageBubbleBottom(message, sent),
      radius,
      gradient: false,
      extra: extra,
      onTap: onTap,
    );
  }
}

/// Used whenever the mime type either doesn't match any specific chat widget or we just
/// cannot determine the mime type.
class FileChatWidget extends StatelessWidget {

  const FileChatWidget(
    this.message,
    this.radius,
    this.sent,
    {
      this.extra,
      Key? key,
    }
  ) : super(key: key);
  final Message message;
  final BorderRadius radius;
  final bool sent;
  final Widget? extra;

  Widget _buildNonDownloaded() {
    return FileChatBaseWidget(
      message,
      Icons.file_present,
      message.isFileUploadNotification ? (message.filename ?? '') : filenameFromUrl(message.srcUrl!),
      radius,
      sent,
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
    return FileChatBaseWidget(
      message,
      Icons.file_present,
      message.isFileUploadNotification ? (message.filename ?? '') : filenameFromUrl(message.srcUrl!),
      radius,
      sent,
      extra: ProgressWidget(id: message.id),
    );
  }

  Widget _buildInner() {
    return FileChatBaseWidget(
      message,
      Icons.file_present,
      message.isFileUploadNotification ? (message.filename ?? '') : filenameFromUrl(message.srcUrl!),
      radius,
      sent,
      onTap: () {
        OpenFile.open(message.mediaUrl);
      },
    );
  }

  Widget _buildWrapper() {
    if (!message.isDownloading && message.mediaUrl != null) return _buildInner();
    if (message.isFileUploadNotification || message.isDownloading) return _buildDownloading();

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
