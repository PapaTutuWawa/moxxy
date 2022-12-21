import 'dart:core';
import 'package:auto_size_text/auto_size_text.dart';
import 'package:flutter/material.dart';
import 'package:moxplatform/moxplatform.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/ui/widgets/chat/bottom.dart';
import 'package:moxxyv2/ui/widgets/chat/downloadbutton.dart';
import 'package:moxxyv2/ui/widgets/chat/media/base.dart';
import 'package:moxxyv2/ui/widgets/chat/progress.dart';

/// A base widget for sent/received files that cannot be displayed otherwise.
class FileChatBaseWidget extends StatelessWidget {
  const FileChatBaseWidget(
    this.message,
    this.icon,
    this.filename,
    this.radius,
    this.maxWidth,
    this.sent,
    {
      this.extra,
      this.onTap,
      super.key,
    }
  );
  final Message message;
  final IconData icon;
  final String filename;
  final BorderRadius radius;
  final double maxWidth;
  final Widget? extra;
  final bool sent;
  final void Function()? onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: maxWidth,
      child: MediaBaseChatWidget(
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 48,
              ),

              Padding(
                padding: const EdgeInsets.only(left: 6),
                child: AutoSizeText(
                  filename,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        MessageBubbleBottom(message, sent),
        radius,
        gradient: false,
        extra: extra,
        onTap: onTap,
      ),
    );
  }
}

/// Used whenever the mime type either doesn't match any specific chat widget or we just
/// cannot determine the mime type.
class FileChatWidget extends StatelessWidget {
  const FileChatWidget(
    this.message,
    this.radius,
    this.maxWidth,
    this.sent,
    {
      this.extra,
      super.key,
    }
  );
  final Message message;
  final BorderRadius radius;
  final bool sent;
  final double maxWidth;
  final Widget? extra;

  Widget _buildNonDownloaded() {
    return FileChatBaseWidget(
      message,
      Icons.file_present,
      message.isFileUploadNotification ? (message.filename ?? '') : filenameFromUrl(message.srcUrl!),
      radius,
      maxWidth,
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
      maxWidth,
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
      maxWidth,
      sent,
      onTap: () {
        openFile(message.mediaUrl!);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!message.isDownloading && message.mediaUrl != null) return _buildInner();
    if (message.isFileUploadNotification || message.isDownloading) return _buildDownloading();

    return _buildNonDownloaded();
  }
}
