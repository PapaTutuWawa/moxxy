import 'dart:io';
import 'package:flutter/material.dart';
import 'package:moxxy_native/moxxy_native.dart';
import 'package:moxxyv2/shared/helpers.dart';

class BaseMediaViewer extends StatelessWidget {
  const BaseMediaViewer({
    required this.child,
    required this.path,
    required this.mime,
    required this.timestamp,
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
          Positioned(
            top: 0,
            left: 0,
            right: 0,
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

Future<void> showMediaViewer(
  BuildContext context,
  WidgetBuilder builder,
) async {
  return showDialog<void>(
    barrierColor: Colors.black87,
    context: context,
    builder: builder,
  );
}
