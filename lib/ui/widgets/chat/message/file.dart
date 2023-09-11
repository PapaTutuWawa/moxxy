import 'dart:core';
import 'package:flutter/material.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/ui/widgets/chat/bottom.dart';
import 'package:moxxyv2/ui/widgets/chat/downloadbutton.dart';
import 'package:moxxyv2/ui/widgets/chat/helpers.dart';
import 'package:moxxyv2/ui/widgets/chat/message/base.dart';
import 'package:moxxyv2/ui/widgets/chat/progress.dart';

/// A base widget for sent/received files that cannot be displayed otherwise.
class FileChatBaseWidget extends StatelessWidget {
  const FileChatBaseWidget(
    this.message,
    this.filename,
    this.radius,
    this.maxWidth,
    this.sent, {
    this.downloadButton,
    this.onTap,
    this.mimeType,
    super.key,
  });
  final Message message;
  final String filename;
  final BorderRadius radius;
  final double maxWidth;
  final Widget? downloadButton;
  final bool sent;
  final void Function()? onTap;
  final String? mimeType;

  IconData _mimeTypeToIcon() {
    if (mimeType == null) return Icons.file_present;

    if (mimeType!.startsWith('image/')) {
      return Icons.image;
    } else if (mimeType!.startsWith('video/')) {
      return Icons.video_file_outlined;
    } else if (mimeType!.startsWith('audio/')) {
      return Icons.music_note;
    }

    return Icons.file_present;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: maxWidth,
      child: MediaBaseChatWidget(
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              if (downloadButton != null) downloadButton!,
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      filename,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _mimeTypeToIcon(),
                            size: 48,
                          ),
                          Text(
                            mimeTypeToName(mimeType),
                            style: const TextStyle(
                              fontSize: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        MessageBubbleBottom(
          message,
          sent,
        ),
        radius,
        gradient: false,
        //extra: extra,
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
    this.sent, {
    this.extra,
    super.key,
  });
  final Message message;
  final BorderRadius radius;
  final bool sent;
  final double maxWidth;
  final Widget? extra;

  Widget _buildNonDownloaded() {
    return FileChatBaseWidget(
      message,
      message.fileMetadata!.filename,
      radius,
      maxWidth,
      sent,
      mimeType: message.fileMetadata!.mimeType,
      downloadButton: DownloadButton(
        onPressed: () => requestMediaDownload(message),
      ),
    );
  }

  Widget _buildDownloading() {
    return FileChatBaseWidget(
      message,
      message.fileMetadata!.filename,
      radius,
      maxWidth,
      sent,
      mimeType: message.fileMetadata!.filename,
      downloadButton: ProgressWidget(message.id),
    );
  }

  Widget _buildInner() {
    return FileChatBaseWidget(
      message,
      message.fileMetadata!.filename,
      radius,
      maxWidth,
      sent,
      mimeType: message.fileMetadata!.mimeType,
      onTap: () {
        openFile(message.fileMetadata!.path!);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!message.isDownloading && message.fileMetadata!.path != null) {
      return _buildInner();
    }
    if (message.isFileUploadNotification || message.isDownloading) {
      return _buildDownloading();
    }

    return _buildNonDownloaded();
  }
}
