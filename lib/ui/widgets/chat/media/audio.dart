import 'dart:async';
import 'dart:io';
import 'package:audiofileplayer/audiofileplayer.dart';
import 'package:flutter/material.dart';
import 'package:moxplatform/moxplatform.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/ui/widgets/chat/bottom.dart';
import 'package:moxxyv2/ui/widgets/chat/downloadbutton.dart';
import 'package:moxxyv2/ui/widgets/chat/media/base.dart';
import 'package:moxxyv2/ui/widgets/chat/media/file.dart';
import 'package:moxxyv2/ui/widgets/chat/progress.dart';

String doubleToTimestamp(double p) {
  if (p < 60) {
    return '0:${padInt(p.floor())}';
  }

  final minutes = (p / 60).floor();
  final seconds = padInt((p - minutes * 60).floor());
  return '$minutes:$seconds';
}

enum _AudioPlaybackState {
  playing,
  paused,
  stopped
}

class _AudioWidget extends StatelessWidget {
  const _AudioWidget(
    this.maxWidth,
    this.isDownloading,
    this.onTap,
    this.icon,
    this.onChanged,
    this.duration,
    this.position,
    this.messageId,
  );
  final double maxWidth;
  final bool isDownloading;
  final void Function() onTap;
  final void Function(double) onChanged;
  final double? duration;
  final double? position;
  final Widget? icon;
  final int messageId;

  Widget _getLeftWidget() {
    if (isDownloading) {
      return SizedBox(
        width: 48,
        height: 48,
        child: ProgressWidget(id: messageId),
      );
    }

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.only(
          left: 8,
          right: 4,
        ),
        child: icon,
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: maxWidth,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _getLeftWidget(),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Slider(
                onChanged: onChanged,
                value: (position != null && duration != null) ?
                  (position! / duration!).clamp(0, 1) :
                  0,
              ),

              SizedBox(
                width: maxWidth - 80,
                child: Row(
                  children: [
                    Text(doubleToTimestamp(position ?? 0)),
                    const Spacer(),
                    Text(doubleToTimestamp(duration ?? 0)),
                  ],
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ],
      ),
    );
  }
}

class AudioChatWidget extends StatefulWidget {
  const AudioChatWidget(
    this.message,
    this.radius,
    this.maxWidth,
    this.sent,
    {
      super.key,
    }
  );
  final Message message;
  final BorderRadius radius;
  final double maxWidth;
  final bool sent;

  @override
  AudioChatState createState() => AudioChatState();
}

class AudioChatState extends State<AudioChatWidget> {
  _AudioPlaybackState _playState = _AudioPlaybackState.stopped;
  double? _duration;
  double? _position;
  Audio? _audioFile;
  
  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void setState(VoidCallback fn) {
    if (mounted) {
      super.setState(fn);
    }
  }
  
  Future<void> _init() async {
    _audioFile = Audio.loadFromAbsolutePath(
      widget.message.mediaUrl!,
      onDuration: (double seconds) {
        setState(() {
          _duration = seconds;
        });
      },
      onPosition: (double seconds) {
        setState(() {
          _position = seconds;
        });
      },
      onComplete: () {
        setState(() {
          _playState = _AudioPlaybackState.stopped;
        });
      },
    );
  }
  
  @override
  void dispose() {
    _audioFile?.dispose();
    super.dispose();
  }
  
  Widget _buildUploading() {
    return MediaBaseChatWidget(
      _AudioWidget(
        widget.maxWidth,
        true,
        () {},
        null,
        (_) {},
        null,
        null,
        widget.message.id,
      ),
      MessageBubbleBottom(widget.message, widget.sent),
      widget.radius,
      gradient: false,
    );
  }

  Widget _buildDownloading() {
    return MediaBaseChatWidget(
      _AudioWidget(
        widget.maxWidth,
        true,
        () {},
        null,
        (_) {},
        null,
        null,
        widget.message.id,
      ),
      MessageBubbleBottom(widget.message, widget.sent),
      widget.radius,
      gradient: false,
    );
  }
  
  /// The audio file exists locally
  Widget _buildAudio() {
    return MediaBaseChatWidget(
      _AudioWidget(
        widget.maxWidth,
        false,
        () {
          if (_playState != _AudioPlaybackState.playing) {
            if (_playState == _AudioPlaybackState.paused) {
              _audioFile?.resume();
            } else if (_playState == _AudioPlaybackState.stopped) {
              _audioFile?.play();
            }

            setState(() {
              _playState = _AudioPlaybackState.playing;
            });
          } else {
            _audioFile?.pause();
            setState(() {
              _playState = _AudioPlaybackState.paused;
            });
          }
        },
        _playState == _AudioPlaybackState.playing ?
          const Icon(Icons.pause) :
          const Icon(Icons.play_arrow),
        (p) {
          if (_duration == null || _audioFile == null) return;

          setState(() {
              _position = p * _duration!;
              _audioFile!.seek(_position!);
          });
        },
        _duration,
        _position,
        widget.message.id,
      ),
      MessageBubbleBottom(widget.message, widget.sent),
      widget.radius,
      gradient: false,
    );
  }

  Widget _buildDownloadable() {
    // TODO(Unknown): Implement
    return FileChatBaseWidget(
      widget.message,
      Icons.image,
      widget.message.isFileUploadNotification ?
        (widget.message.filename ?? '') :
        filenameFromUrl(widget.message.srcUrl!),
      widget.radius,
      widget.sent,
      extra: DownloadButton(
        onPressed: () {
          MoxplatformPlugin.handler.getDataSender().sendData(
            RequestDownloadCommand(message: widget.message),
            awaitable: false,
          );
        },
      ),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    if (widget.message.isUploading) return _buildUploading();
    if (widget.message.isFileUploadNotification || widget.message.isDownloading) return _buildDownloading();

    // TODO(PapaTutuWawa): Maybe use an async builder
    if (widget.message.mediaUrl != null && File(widget.message.mediaUrl!).existsSync()) return _buildAudio();
    
    return _buildDownloadable();
  }
}
