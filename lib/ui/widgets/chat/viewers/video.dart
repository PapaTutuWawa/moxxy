import 'dart:async';
import 'package:flutter/material.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/ui/widgets/chat/viewers/base.dart';
import 'package:video_player/video_player.dart';

/// A UI element that allows the user to play/pause the video.
class VideoViewerPlayButton extends StatefulWidget {
  const VideoViewerPlayButton({
    required this.videoController,
    required this.uiController,
    super.key,
  });

  /// The controller controlling the video player.
  final VideoPlayerController videoController;

  /// The controller controlling the visibility of UI elements.
  final ViewerUIVisibilityController uiController;

  @override
  VideoViewerPlayButtonState createState() => VideoViewerPlayButtonState();
}

class VideoViewerPlayButtonState extends State<VideoViewerPlayButton> {
  late bool _showPlayButton;

  @override
  void initState() {
    super.initState();

    _showPlayButton = widget.uiController.visible.value;
    widget.uiController.visible.addListener(_handleValueChange);
  }

  @override
  void dispose() {
    super.dispose();

    widget.uiController.visible.removeListener(_handleValueChange);
  }

  void _handleValueChange() {
    setState(() {
      _showPlayButton = widget.uiController.visible.value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: widget.videoController,
      builder: (context, value, _) {
        return AnimatedOpacity(
          opacity: _showPlayButton ? 1 : 0,
          duration: mediaViewerAnimationDuration,
          child: IgnorePointer(
            ignoring: !_showPlayButton,
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(64),
                child: Material(
                  color: Colors.black54,
                  child: SizedBox(
                    width: 64,
                    height: 64,
                    child: Center(
                      child: InkWell(
                        child: Icon(
                          value.isPlaying ? Icons.pause : Icons.play_arrow,
                          size: 64,
                        ),
                        onTap: () {
                          if (value.isPlaying) {
                            widget.videoController.pause();
                          } else {
                            widget.videoController.play();
                          }

                          widget.uiController.startHideTimer();
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// UI element that displays the current timecode and duration of the video, and
/// allows the user to scrub through the video.
class VideoViewerScrubber extends StatefulWidget {
  const VideoViewerScrubber({
    required this.videoController,
    required this.uiController,
    super.key,
  });

  /// The controller controlling the video player.
  final VideoPlayerController videoController;

  /// The controller controlling the visibility of UI elements.
  final ViewerUIVisibilityController uiController;

  @override
  VideoViewerScrubberState createState() => VideoViewerScrubberState();
}

class VideoViewerScrubberState extends State<VideoViewerScrubber> {
  late bool _showScrubBar;

  @override
  void initState() {
    super.initState();

    _showScrubBar = widget.uiController.visible.value;
    widget.uiController.visible.addListener(_handleValueChange);
  }

  @override
  void dispose() {
    widget.uiController.visible.removeListener(_handleValueChange);

    super.dispose();
  }

  void _handleValueChange() {
    setState(() {
      _showScrubBar = widget.uiController.visible.value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !_showScrubBar,
      child: AnimatedOpacity(
        opacity: _showScrubBar ? 1 : 0,
        duration: mediaViewerAnimationDuration,
        child: Material(
          color: Colors.black54,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 32,
              vertical: 8,
            ),
            child: ValueListenableBuilder(
              valueListenable: widget.videoController,
              builder: (context, value, _) {
                return Row(
                  children: [
                    Text(
                      formatDuration(value.position),
                    ),
                    Expanded(
                      child: Slider(
                        value: value.position.inSeconds.toDouble(),
                        max: value.duration.inSeconds.toDouble(),
                        onChanged: (value) {
                          widget.videoController.seekTo(
                            Duration(seconds: value.toInt()),
                          );
                        },
                      ),
                    ),
                    Text(
                      formatDuration(value.duration),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class VideoViewer extends StatefulWidget {
  const VideoViewer({
    required this.path,
    required this.controller,
    super.key,
  });

  /// The controller controlling UI element visibility.
  final ViewerUIVisibilityController controller;

  /// The path to the video we're showing.
  final String path;

  @override
  VideoViewerState createState() => VideoViewerState();
}

class VideoViewerState extends State<VideoViewer> {
  late final VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.contentUri(
      Uri.file(widget.path),
    )..initialize().then((_) {
        setState(() {});
      });
  }

  @override
  void dispose() {
    _controller.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized) {
      return const Center(
        child: SizedBox(
          width: 60,
          height: 60,
          child: CircularProgressIndicator(),
        ),
      );
    }

    return Center(
      child: AspectRatio(
        aspectRatio: _controller.value.aspectRatio,
        child: GestureDetector(
          onTap: widget.controller.handleTap,
          child: Stack(
            children: [
              Positioned.fill(
                child: VideoPlayer(_controller),
              ),
              VideoViewerPlayButton(
                videoController: _controller,
                uiController: widget.controller,
              ),
              Positioned(
                left: 0,
                bottom: 0,
                right: 0,
                child: VideoViewerScrubber(
                  videoController: _controller,
                  uiController: widget.controller,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Show a dialog using [context] that allows the user to view an image at path
/// [path] and optionally share it. [mime] is the image's exact mime type.
Future<void> showVideoViewer(
  BuildContext context,
  int timestamp,
  String path,
  String mime,
) async {
  await showMediaViewer(
    context,
    (context, controller) {
      return BaseMediaViewer(
        path: path,
        mime: mime,
        timestamp: timestamp,
        controller: controller,
        child: VideoViewer(
          path: path,
          controller: controller,
        ),
      );
    },
  );
}
