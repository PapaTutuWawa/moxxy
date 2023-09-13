import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/widgets/messaging_textfield/controller.dart';
import 'package:moxxyv2/ui/widgets/messaging_textfield/overlay.dart';

/// Describes on what axis the record button is locked.
enum AxisLock {
  /// The record button can only move on the horizontal axis.
  horizonal,

  /// The record button can only move on the vertical axis.
  vertical,

  /// The record button is "stuck" at the origin (the record icon).
  origin,
}

class RecordIcon extends StatefulWidget {
  const RecordIcon(
    this.controller, {
    super.key,
  });

  final MobileMessagingTextFieldController controller;

  @override
  RecordIconState createState() => RecordIconState();
}

class RecordIconState extends State<RecordIcon> {
  /// The initial position of the pointer during the pointer down event.
  Offset _initialPosition = Offset.zero;

  /// The position of the button when locked. This value is set to (0, 0) because
  /// we need access to the MediaQuery to properly calculate the position.
  Offset _buttonLockPosition = Offset.zero;

  /// Keep track if we have already vibrated for a "lock" event.
  bool hasVibrated = false;

  double _cancellationDistance = 0;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) {
        final size = MediaQuery.of(context).size;
        _initialPosition = event.position;

        final buttonX = 8 + 45 + 16 + 8 - (80 - 45) / 2;
        _buttonLockPosition = Offset(
          8 + 45 + 16 + 8 - (80 - 45) / 2,
          size.height - 250 - 80,
        );
        _cancellationDistance = (size.width - buttonX - 80) * 0.8;
        widget.controller.startRecording(context);
      },
      onPointerMove: (event) {
        final delta = event.position - _initialPosition;
        final dxRaw = delta.dx;
        final dyRaw = delta.dy;
        final dx = delta.dx.abs();
        final dy = delta.dy.abs();

        // Figure out what axis to lock.
        AxisLock lock;
        if (dy > dx) {
          lock = AxisLock.vertical;
        } else if (dx > dy) {
          lock = AxisLock.horizonal;
          // Prevent locking, then moving to horizontal from counting
          // as "locked".
          widget.controller.lockedNotifier.value = false;
        } else {
          lock = AxisLock.origin;
          // Prevent locking, then moving to horizontal from counting
          // as "locked".
          widget.controller.lockedNotifier.value = false;
        }

        // Lock the dragging to a given axis.
        final size = MediaQuery.of(context).size;
        double x;
        double y;
        switch (lock) {
          case AxisLock.origin:
            x = 8 + 45 + 16 + 8 - (80 - 45) / 2;
            y = size.height - 8 - 80 + 40 / 2;
            break;
          case AxisLock.vertical:
            x = 8 + 45 + 16 + 8 - (80 - 45) / 2;
            y = size.height - 8 + dyRaw;
            break;
          case AxisLock.horizonal:
            x = 8 + 45 + 16 + 8 - (80 - 45) / 2 - dxRaw;
            y = size.height - 8 - 80 + 40 / 2;
            break;
        }

        // Handle haptic feedback and locking once we reach a certain
        // threshold.
        if (dy >= 250 - 45) {
          if (!hasVibrated) {
            hasVibrated = true;
            widget.controller.lockedNotifier.value = true;
            unawaited(HapticFeedback.heavyImpact());
            print('[MOVE] Triggering haptic feedback');
          }

          widget.controller.positionNotifier.value = _buttonLockPosition;
          return;
        } else {
          if (hasVibrated) {
            widget.controller.lockedNotifier.value = false;
            hasVibrated = false;
          }
        }

        // Handle cancelling the recording.
        if (dx >= _cancellationDistance && !widget.controller.isCancellingNotifier.value) {
          widget.controller.isCancellingNotifier.value = true;
          unawaited(HapticFeedback.heavyImpact());
          print('[MOVE] Triggering haptic feedback');
        } else if (dx < _cancellationDistance && widget.controller.isCancellingNotifier.value) {
          widget.controller.isCancellingNotifier.value = false;
        }

        // Clamp the position to not move off of the screen.
        widget.controller.positionNotifier.value = Offset(
          x.clamp(
            8 + 45 + 16 + 8 - (recordButtonSize - 45) / 2,
            double.infinity,
          ),
          y.clamp(
            -double.infinity,
            size.height - 8 - recordButtonSize + 40 / 2,
          ),
        );
      },
      onPointerUp: (event) {
        if (widget.controller.requestingPermission) {
          return;
        }

        print('onPointerUp');

        // Reset the dragging value.
        widget.controller.draggingNotifier.value = false;

        // End the recording if the button is not locked.
        if (!widget.controller.lockedNotifier.value) {
          widget.controller.endRecording();
        }
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onLongPress: () {
              //widget.controller.draggingNotifier.value = true;
            },
            child: const Padding(
              padding: EdgeInsets.all(8),
              child: Icon(
                Icons.mic_sharp,
                color: primaryColor,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
