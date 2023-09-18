import 'dart:async';
import 'package:flutter/material.dart';
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/ui/widgets/chat/viewers/base.dart';
import 'package:video_player/video_player.dart';

/// This controller deals with showing/hiding the UI elements and handling the timeouts
/// for hiding the elements when they are visible.
class VideoViewerUIVisibilityController {
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
  final VideoViewerUIVisibilityController uiController;

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
          duration: const Duration(milliseconds: 150),
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
  final VideoViewerUIVisibilityController uiController;

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
        duration: const Duration(milliseconds: 150),
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
    super.key,
  });

  final String path;

  @override
  VideoViewerState createState() => VideoViewerState();
}

class VideoViewerState extends State<VideoViewer> {
  late final VideoPlayerController _controller;

  final VideoViewerUIVisibilityController _uiController =
      VideoViewerUIVisibilityController();

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
    _uiController.dispose();

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
          onTap: _uiController.handleTap,
          child: Stack(
            children: [
              Positioned.fill(
                child: VideoPlayer(_controller),
              ),
              VideoViewerPlayButton(
                videoController: _controller,
                uiController: _uiController,
              ),
              Positioned(
                left: 0,
                bottom: 0,
                right: 0,
                child: VideoViewerScrubber(
                  videoController: _controller,
                  uiController: _uiController,
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
  return showMediaViewer(
    context,
    (context) {
      return BaseMediaViewer(
        path: path,
        mime: mime,
        timestamp: timestamp,
        child: VideoViewer(
          path: path,
        ),
      );
    },
  );
}
