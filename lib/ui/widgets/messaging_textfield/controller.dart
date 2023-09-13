import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:moxxy_native/moxxy_native.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/ui/widgets/messaging_textfield/overlay.dart';
import 'package:moxxyv2/ui/widgets/timer/controller.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

typedef PositionValueNotifier = ValueNotifier<Offset>;
typedef BooleanValueNotifier = ValueNotifier<bool>;

class MobileMessagingTextFieldController {
  MobileMessagingTextFieldController(this.conversationJid);

  final PositionValueNotifier positionNotifier =
      ValueNotifier<Offset>(Offset.zero);
  final BooleanValueNotifier lockedNotifier = BooleanValueNotifier(false);
  final BooleanValueNotifier draggingNotifier = BooleanValueNotifier(false);
  final BooleanValueNotifier keepSliderNotifier = BooleanValueNotifier(false);
  final BooleanValueNotifier isRecordingNotifier = BooleanValueNotifier(false);
  final BooleanValueNotifier isCancellingNotifier = BooleanValueNotifier(false);

  AnimationController? _animationController;
  Animation<int>? animation;

  final TimerController timerController = TimerController();

  OverlayEntry? _overlayEntry;

  bool requestingPermission = false;

  /// The audio recorder.
  final Record _recorder = Record();

  /// The JID of the currently opened chat.
  final String conversationJid;

  void register(AnimationController controller) {
    _animationController = controller;
    _animationController!.addStatusListener(_onAnimationStatusChanged);
    isCancellingNotifier.addListener(_onIsCancellingChanged);
  }

  void dispose() {
    _animationController?.removeStatusListener(_onAnimationStatusChanged);
    isCancellingNotifier.removeListener(_onIsCancellingChanged);
    removeOverlay();
    _recorder.dispose();
  }

  void _onIsCancellingChanged() {
    if (isCancellingNotifier.value == true) {
      endRecording();
    }
  }

  void _onAnimationStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.dismissed && !isRecordingNotifier.value) {
      keepSliderNotifier.value = false;
      lockedNotifier.value = false;
      removeOverlay();
    }
  }

  Future<void> _startAudioRecording() async {
    final now = DateTime.now();
    final filename =
        'audio_${now.year}${now.month}${now.day}${now.hour}${now.second}.aac';
    final recordingFilePath = path.join(
      await MoxxyPlatformApi().getCacheDataPath(),
      filename,
    );
    await _recorder.start(
      path: recordingFilePath,
    );
  }

  Future<void> _cancelAudioRecording() async {
    final file = await _recorder.stop();

    if (file != null) {
      unawaited(File(file).delete());
    }
  }

  Future<void> _endAudioRecording() async {
    final file = await _recorder.stop();
    if (file == null) {
      await Fluttertoast.showToast(
        msg: t.errors.conversation.audioRecordingError,
        gravity: ToastGravity.SNACKBAR,
        toastLength: Toast.LENGTH_SHORT,
      );
      return;
    }

    // Send the file.
    await getForegroundService().send(
      SendFilesCommand(
        paths: [file],
        recipients: [conversationJid],
      ),
      awaitable: false,
    );
  }

  Future<void> startRecording(BuildContext context) async {
    // Make sure that part of the UI looks locked at this point.
    draggingNotifier.value = false;
    isRecordingNotifier.value = true;

    // Prevent weird issues with the popup leading to us losing track of the pointer.
    requestingPermission = true;
    final canRecord =
        await Permission.microphone.status == PermissionStatus.granted;

    // "Forward" the UI
    unawaited(_animationController!.forward());
    isCancellingNotifier.value = false;
    keepSliderNotifier.value = true;

    if (!canRecord) {
      // Make the UI appear as if we just locked it
      lockedNotifier.value = true;

      final requestResult = await Permission.microphone.request();
      requestingPermission = false;

      // If we successfully requested the permission, actually start recording. If not,
      // tell the user and cancel the process.
      if (requestResult == PermissionStatus.granted) {
        timerController.runningNotifier.value = true;
        await _startAudioRecording();
      } else {
        isCancellingNotifier.value = true;
        await endRecording();
        await Fluttertoast.showToast(
          msg: t.warnings.conversation.microphoneDenied,
          toastLength: Toast.LENGTH_LONG,
        );
        return;
      }
    } else {
      requestingPermission = false;
      draggingNotifier.value = true;

      timerController.runningNotifier.value = true;
      // ignore: use_build_context_synchronously
      createOverlay(context);
      await _startAudioRecording();
    }
  }

  void cancelRecording() {
    isCancellingNotifier.value = true;
    endRecording();
    _cancelAudioRecording();
  }

  Future<void> endRecording() async {
    draggingNotifier.value = false;
    isRecordingNotifier.value = false;
    await _animationController?.reverse();
    timerController.runningNotifier.value = false;

    if (!isCancellingNotifier.value) {
      if (timerController.runtime >= 1) {
        await _endAudioRecording();
      } else {
        await _cancelAudioRecording();
        await Fluttertoast.showToast(
          msg: t.warnings.conversation.holdForLonger,
          toastLength: Toast.LENGTH_SHORT,
        );
      }
    }

    // Mak sure that the time starts at 0 again.
    timerController.reset();
  }

  void createOverlay(BuildContext context) {
    removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return RecordButtonOverlay(this);
      },
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}
