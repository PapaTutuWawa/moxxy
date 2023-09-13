import 'dart:async';
import 'package:flutter/material.dart';
import 'package:moxxyv2/ui/widgets/messaging_textfield/overlay.dart';
import 'package:moxxyv2/ui/widgets/timer/controller.dart';
import 'package:permission_handler/permission_handler.dart';

typedef PositionValueNotifier = ValueNotifier<Offset>;
typedef BooleanValueNotifier = ValueNotifier<bool>;

class MobileMessagingTextFieldController {
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

  void register(AnimationController controller) {
    _animationController = controller;
    _animationController!.addStatusListener(_onAnimationStatusChanged);
    isCancellingNotifier.addListener(_onIsCancellingChanged);
  }

  void dispose() {
    _animationController?.removeStatusListener(_onAnimationStatusChanged);
    isCancellingNotifier.removeListener(_onIsCancellingChanged);
    removeOverlay();
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
        // TODO: Start recording
        timerController.runningNotifier.value = true;
      } else {
        // TODO: Show a toast, saying we cannot do that.
        print('[STUB] No permission');
        isCancellingNotifier.value = true;
        endRecording();
        return;
      }
    } else {
      requestingPermission = false;
      draggingNotifier.value = true;

      timerController.runningNotifier.value = true;
      createOverlay(context);
    }
  }

  void cancelRecording() {
    isCancellingNotifier.value = true;
    endRecording();
  }

  void endRecording() {
    draggingNotifier.value = false;
    isRecordingNotifier.value = false;
    _animationController?.reverse();
    timerController.runningNotifier.value = false;

    if (!isCancellingNotifier.value) {
      if (timerController.runtime >= 1) {
        onRecordingDone();
      } else {
        // TODO: Show a toast saying that the message was too short
        print('[STUB] Recording too short');
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

  void onRecordingDone() {
    print('[STUB] Sending voice message');
  }
}
