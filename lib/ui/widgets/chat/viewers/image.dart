import 'dart:io';
import 'package:flutter/material.dart';
import 'package:moxxyv2/ui/widgets/chat/viewers/base.dart';

class ImageViewer extends StatelessWidget {
  const ImageViewer({
    required this.path,
    required this.controller,
    super.key,
  });

  /// The controller for UI visibility.
  final ViewerUIVisibilityController controller;

  /// The path to display.
  final String path;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: controller.handleTap,
      child: InteractiveViewer(
        child: Image.file(File(path)),
      ),
    );
  }
}

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
        child: ImageViewer(
          path: path,
          controller: controller,
        ),
      );
    },
  );
}
