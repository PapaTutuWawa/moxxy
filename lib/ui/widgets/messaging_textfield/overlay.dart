import 'package:flutter/material.dart';
import 'package:moxxyv2/ui/pages/conversation/blink.dart';
import 'package:moxxyv2/ui/widgets/messaging_textfield/constants.dart';
import 'package:moxxyv2/ui/widgets/messaging_textfield/controller.dart';


class RecordButtonOverlay extends StatefulWidget {
  const RecordButtonOverlay(
    this.controller, {
    super.key,
  });

  final MobileMessagingTextFieldController controller;

  @override
  RecordButtonOverlayState createState() => RecordButtonOverlayState();
}

class RecordButtonOverlayState extends State<RecordButtonOverlay> {
  /// The current position of the record button.
  Offset? _position;

  /// Flag (updates in _onValueChanged) that indicates whether the elements in this
  /// overlay should be shown. This is done to allow animating the elements out when
  /// the recording is stopped.
  bool _showElements = true;

  @override
  void initState() {
    super.initState();

    widget.controller.positionNotifier.addListener(_onValueChanged);
    widget.controller.lockedNotifier.addListener(_onValueChanged);
    widget.controller.draggingNotifier.addListener(_onValueChanged);
    widget.controller.isRecordingNotifier.addListener(_onValueChanged);
  }

  @override
  void dispose() {
    widget.controller.positionNotifier.removeListener(_onValueChanged);
    widget.controller.lockedNotifier.removeListener(_onValueChanged);
    widget.controller.draggingNotifier.removeListener(_onValueChanged);
    widget.controller.isRecordingNotifier.removeListener(_onValueChanged);

    super.dispose();
  }

  void _onValueChanged() {
    setState(() {
      _showElements = widget.controller.draggingNotifier.value &&
          widget.controller.isRecordingNotifier.value;
      _position = widget.controller.positionNotifier.value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(),
        Positioned(
          right: lockButtonHorizontalCenteringOffset,
          bottom: 250,
          child: AnimatedScale(
            scale: _showElements ? 1 : 0,
            duration: const Duration(milliseconds: 150),
            child: SizedBox(
              width: lockButtonWidth,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.grey,
                  borderRadius: BorderRadius.circular(recordButtonSize),
                ),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(top: 8),
                        child: Icon(
                          Icons.lock_sharp,
                          color: Colors.white,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 4, bottom: 8),
                        child: Icon(
                          Icons.expand_less,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          right: _position?.dx ?? recordButtonHorizontalCenteringOffset,
          top: _position?.dy ??
              MediaQuery.of(context).size.height - recordButtonVerticalCenteringOffset,
          child: AnimatedScale(
            scale: _showElements ? 1 : 0,
            duration: const Duration(milliseconds: 150),
            child: SizedBox(
              width: recordButtonSize,
              height: recordButtonSize,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(recordButtonSize),
                ),
                child: Center(
                  child: BlinkingIcon(
                    icon: Icons.mic_sharp,
                    duration: const Duration(milliseconds: 600),
                    start: Colors.white,
                    end: Colors.red.shade600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
