import 'package:flutter/material.dart';
import 'package:moxxyv2/shared/models/file_metadata.dart';
import 'package:moxxyv2/ui/widgets/chat/playbutton.dart';
import 'package:moxxyv2/ui/widgets/chat/shared/audio.dart';
import 'package:moxxyv2/ui/widgets/chat/shared/file.dart';
import 'package:moxxyv2/ui/widgets/chat/shared/image.dart';
import 'package:moxxyv2/ui/widgets/chat/shared/video.dart';

typedef SharedMediaWidgetCallback = void Function(FileMetadata);

/// Build a widget to represent a shared media file.
Widget buildSharedMediaWidget(
  FileMetadata metadata,
  String conversationJid,
  SharedMediaWidgetCallback onTap, {
  SharedMediaWidgetCallback? onLongPress,
}) {
  // Prevent having the phone vibrate if no onLongPress is passed
  final longPressCallback =
      onLongPress != null ? () => onLongPress(metadata) : null;

  if (metadata.mimeType!.startsWith('image/')) {
    return SharedImageWidget(
      metadata.path!,
      onTap: () => onTap(metadata),
      onLongPress: longPressCallback,
    );
  } else if (metadata.mimeType!.startsWith('video/')) {
    return SharedVideoWidget(
      metadata.path!,
      conversationJid,
      metadata.mimeType!,
      onTap: () => onTap(metadata),
      onLongPress: () => onLongPress?.call(metadata),
      child: const PlayButton(size: 32),
    );
  } else if (metadata.mimeType!.startsWith('audio/')) {
    return SharedAudioWidget(
      metadata.path!,
      onTap: () => onTap(metadata),
      onLongPress: longPressCallback,
    );
  }

  return SharedFileWidget(
    metadata.path!,
    onTap: () => onTap(metadata),
    onLongPress: longPressCallback,
  );
}
