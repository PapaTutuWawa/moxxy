import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:moxxy_native/moxxy_native.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/ui/constants.dart';

/// This controller deals with showing/hiding the UI elements and handling the timeouts
/// for hiding the elements when they are visible.
class ViewerUIVisibilityController {
  final ValueNotifier<bool> visible = ValueNotifier(true);

  Timer? _hideTimer;

  void _disposeHideTimer() {
    _hideTimer?.cancel();
    _hideTimer = null;
  }

  void dispose() {
    _disposeHideTimer();
  }

  /// Start the hide timer.
  void startHideTimer() {
    _disposeHideTimer();

    _hideTimer = Timer.periodic(
      const Duration(seconds: 2),
      (__) {
        _hideTimer?.cancel();
        _hideTimer = null;

        visible.value = !visible.value;
      },
    );
  }

  /// Start or stop the hide timer, depending on the current visibility state.
  void handleTap() {
    if (!visible.value) {
      startHideTimer();
    } else {
      _disposeHideTimer();
    }

    visible.value = !visible.value;
  }
}

class BaseMediaViewer extends StatelessWidget {
  const BaseMediaViewer({
    required this.child,
    required this.path,
    required this.mime,
    required this.timestamp,
    required this.controller,
    super.key,
  });

  /// The child to display.
  final Widget child;

  /// The media item's path. Used for sharing.
  final String path;

  /// The media item's path. Used for sharing.
  final String mime;

  /// The timestamp of the message containing the media item.
  final int timestamp;

  final ViewerUIVisibilityController controller;

  @override
  Widget build(BuildContext context) {
    // Compute a nice display of the message's timestamp.
    final timestampDateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final dateFormat = formatDateBubble(
      timestampDateTime,
      DateTime.now(),
    );
    final timeFormat =
        '${timestampDateTime.hour}:${padInt(timestampDateTime.minute)}';
    final timestampFormat = '$dateFormat, $timeFormat';

    return SafeArea(
      child: Stack(
        children: [
          Positioned.fill(
            child: child,
          ),
          ValueListenableBuilder(
            valueListenable: controller.visible,
            builder: (context, value, child) {
              return AnimatedPositioned(
                top: value ? 0 : -kToolbarHeight,
                left: 0,
                right: 0,
                duration: mediaViewerAnimationDuration,
                child: child!,
              );
            },
            child: SizedBox(
              height: kToolbarHeight,
              child: ColoredBox(
                color: Colors.black45,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const CloseButton(),
                    Expanded(
                      child: Center(
                        child: Text(
                          timestampFormat,
                          style: const TextStyle(
                            fontSize: 20,
                          ),
                        ),
                      ),
                    ),
                    // Sharing is only really applicable on Android and iOS
                    if (Platform.isAndroid || Platform.isIOS)
                      IconButton(
                        icon: const Icon(Icons.share),
                        onPressed: () {
                          MoxxyPlatformApi().shareItems(
                            [
                              ShareItem(
                                path: path,
                                mime: mime,
                              ),
                            ],
                            mime,
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

typedef MediaViewerBuilder = Widget Function(
  BuildContext,
  ViewerUIVisibilityController,
);

/// A wrapper function that shows a dialog to be used as a media viewer. This function
/// handles creation of the UI visibility controller, showing the dialog, and disposing
/// of the controller.
Future<void> showMediaViewer(
  BuildContext context,
  MediaViewerBuilder builder,
) async {
  final controller = ViewerUIVisibilityController();
  await showDialog<void>(
    barrierColor: Colors.black87,
    context: context,
    builder: (context) => builder(context, controller),
  );
  controller.dispose();
}
