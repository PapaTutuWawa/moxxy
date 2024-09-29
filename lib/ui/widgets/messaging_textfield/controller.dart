import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:moxxy_native/moxxy_native.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/ui/widgets/messaging_textfield/overlay.dart';
import 'package:moxxyv2/ui/widgets/messaging_textfield/slider.dart';
import 'package:moxxyv2/ui/widgets/timer/controller.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

typedef PositionValueNotifier = ValueNotifier<Offset>;
typedef BooleanValueNotifier = ValueNotifier<bool>;

class MobileMessagingTextFieldController {
  MobileMessagingTextFieldController(this.conversationJid);

  /// A notifier that carries the current (right, top) coordinates of the recording
  /// button overlay.
  final PositionValueNotifier positionNotifier =
      ValueNotifier<Offset>(Offset.zero);

  /// A notifier that carries the current lock state of the recording, i.e. if the
  /// recording should continue after the pointer up event (true) or end (false).
  final BooleanValueNotifier lockedNotifier = BooleanValueNotifier(false);

  /// A notifier that carries a flag indicating whether the recording button is currently
  /// being dragged (true) or not (false).
  final BooleanValueNotifier draggingNotifier = BooleanValueNotifier(false);

  /// A notifier that carries a flag indicating whether the overlay should still be visible
  /// (true) or not (false). This is used to allow animating the overlay "out" instead of it
  /// just disappearing.
  final BooleanValueNotifier keepSliderNotifier = BooleanValueNotifier(false);

  /// A notifier that carries a flag indicating whether we've started the process of recording
  /// (true) or not (false).
  final BooleanValueNotifier isRecordingNotifier = BooleanValueNotifier(false);

  /// A notifier that carries a flag indicating whether the recording should be cancelled (true)
  /// or not (false).
  final BooleanValueNotifier isCancellingNotifier = BooleanValueNotifier(false);

  /// The [AnimationController] that controls the animation of the [TextFieldSlider].
  AnimationController? _animationController;

  /// The controller that manages starting/stopping the recording time indicator.
  final TimerController timerController = TimerController();

  /// The currently displayed overlay managed by this class.
  OverlayEntry? _overlayEntry;

  /// Flag whether we're currently requesting permission to access the microphone (true)
  /// or not (false). Useful to prevent weird things from happening if the permission popup
  /// causes a [PointerUpEvent].
  bool requestingPermission = false;

  /// The audio recorder.
  final AudioRecorder _recorder = AudioRecorder();

  /// The JID of the currently opened chat.
  final String conversationJid;

  /// Prepare the controller for real usage.
  void register(AnimationController controller) {
    _animationController = controller;
    _animationController!.addStatusListener(_onAnimationStatusChanged);
    isCancellingNotifier.addListener(_onIsCancellingChanged);
  }

  /// Dispose of everything in the class.
  Future<void> dispose() async {
    _animationController?.removeStatusListener(_onAnimationStatusChanged);
    isCancellingNotifier.removeListener(_onIsCancellingChanged);
    _removeOverlay();

    // Get rid of the audio recorder.
    if (await _recorder.isRecording()) {
      await _cancelAudioRecording();
    }
    await _recorder.dispose();
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
      _removeOverlay();
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
      const RecordConfig(),
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
      _createOverlay(context);
      await _startAudioRecording();
    }
  }

  /// Wrapper around [endRecording] that also sets [isCancellingNotifier]'s value
  /// to true to discard a recording.
  void cancelRecording() {
    isCancellingNotifier.value = true;
    endRecording();
  }

  /// Ends audio recording and either discards the recording or sends the file
  /// to the currently opened chat.
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
    await _cancelAudioRecording();
  }

  void _createOverlay(BuildContext context) {
    _removeOverlay();

    _overlayEntry = OverlayEntry(
      builder: (context) {
        return RecordButtonOverlay(this);
      },
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}
