import 'dart:io';
import 'package:flutter/material.dart';
import 'package:moxxyv2/ui/widgets/chat/viewers/base.dart';

/// Show a dialog using [context] that allows the user to view an image at path
/// [path] and optionally share it. [mime] is the image's exact mime type.
Future<void> showImageViewer(
  BuildContext context,
  int timestamp,
  String path,
  String mime,
) async {
  return showMediaViewer(
    context,
    (context, controller) {
      return BaseMediaViewer(
        path: path,
        mime: mime,
        timestamp: timestamp,
        controller: controller,
        child: GestureDetector(
          onTap: controller.handleTap,
          child: InteractiveViewer(
            child: Image.file(File(path)),
          ),
        ),
      );
    },
  );
}
