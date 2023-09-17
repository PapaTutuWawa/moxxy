import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/ui/widgets/messaging_textfield/constants.dart';
import 'package:moxxyv2/ui/widgets/messaging_textfield/controller.dart';

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
    required this.visible,
    super.key,
  });

  /// The controller managing voice message recording.
  final MobileMessagingTextFieldController controller;

  /// Flag indicating whether the widget should be visible or not.
  final bool visible;

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

  /// The distance to drag the pointer to the left to cancel the voice recording.
  double _cancellationDistance = 0;

  /// Flag indicating whether the widget should be layouted, painted, and hit tested
  /// (true) or handled off stage (false).
  bool _takeUpSpace = true;

  @override
  Widget build(BuildContext context) {
    return Offstage(
      offstage: !_takeUpSpace,
      child: AnimatedOpacity(
        opacity: widget.visible ? 1 : 0,
        duration: const Duration(milliseconds: 200),
        onEnd: () {
          // Ensure that we do not layout the child when it should not
          // be visible.
          setState(() {
            _takeUpSpace = widget.visible;
          });
        },
        child: Listener(
          onPointerDown: (event) {
            // Get rid of the keyboard.
            dismissSoftKeyboard(context);

            final size = MediaQuery.of(context).size;
            _initialPosition = event.position;

            const buttonX = recordButtonHorizontalCenteringOffset;
            _buttonLockPosition = Offset(
              recordButtonHorizontalCenteringOffset,
              size.height - lockButtonBottomPosition - recordButtonSize,
            );
            _cancellationDistance =
                (size.width - buttonX - recordButtonSize) * 0.8;
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
            final (x, y) = switch (lock) {
              AxisLock.origin => (
                  recordButtonHorizontalCenteringOffset,
                  size.height - recordButtonVerticalCenteringOffset,
                ),
              AxisLock.vertical => (
                  recordButtonHorizontalCenteringOffset,
                  size.height - recordButtonVerticalCenteringOffset + dyRaw,
                ),
              AxisLock.horizonal => (
                  recordButtonHorizontalCenteringOffset - dxRaw,
                  size.height - recordButtonVerticalCenteringOffset,
                ),
            };

            // Handle haptic feedback and locking once we reach a certain
            // threshold.
            if (dy >= lockButtonBottomPosition - lockButtonHeight / 2) {
              if (!hasVibrated) {
                hasVibrated = true;
                widget.controller.lockedNotifier.value = true;
                unawaited(HapticFeedback.heavyImpact());
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
            if (dx >= _cancellationDistance &&
                !widget.controller.isCancellingNotifier.value) {
              widget.controller.isCancellingNotifier.value = true;
              unawaited(HapticFeedback.heavyImpact());
            } else if (dx < _cancellationDistance &&
                widget.controller.isCancellingNotifier.value) {
              widget.controller.isCancellingNotifier.value = false;
            }

            // Clamp the position to not move off of the screen.
            widget.controller.positionNotifier.value = Offset(
              x.clamp(
                recordButtonHorizontalCenteringOffset,
                double.infinity,
              ),
              y.clamp(
                -double.infinity,
                size.height - recordButtonVerticalCenteringOffset,
              ),
            );
          },
          onPointerUp: (event) {
            if (widget.controller.requestingPermission) {
              return;
            }

            // Reset the dragging value.
            widget.controller.draggingNotifier.value = false;

            // End the recording if the button is not locked.
            if (!widget.controller.lockedNotifier.value) {
              widget.controller.endRecording();
            }
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: const Material(
              color: Colors.transparent,
              child: InkWell(
                child: Padding(
                  padding: iconPadding,
                  child: Icon(
                    Icons.mic_sharp,
                    color: primaryColor,
                    size: iconSize,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
