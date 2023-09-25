import 'package:flutter/material.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/ui/theme.dart';
import 'package:moxxyv2/ui/widgets/messaging_textfield/constants.dart';
import 'package:moxxyv2/ui/widgets/messaging_textfield/controller.dart';
import 'package:moxxyv2/ui/widgets/timer/timer.dart';

class TextFieldSlider extends StatefulWidget {
  const TextFieldSlider({
    required this.controller,
    required this.animation,
    super.key,
  });

  final Animation<int> animation;

  final MobileMessagingTextFieldController controller;

  @override
  TextFieldSliderState createState() => TextFieldSliderState();
}

class TextFieldSliderState extends State<TextFieldSlider> {
  bool _showCancelButton = false;

  @override
  void initState() {
    super.initState();

    widget.controller.keepSliderNotifier.addListener(_onValueChanged);
    widget.controller.isRecordingNotifier.addListener(_onValueChanged);
    widget.controller.draggingNotifier.addListener(_onValueChanged);
  }

  @override
  void dispose() {
    widget.controller.keepSliderNotifier.removeListener(_onValueChanged);
    widget.controller.isRecordingNotifier.removeListener(_onValueChanged);
    widget.controller.draggingNotifier.removeListener(_onValueChanged);

    super.dispose();
  }

  void _onValueChanged() {
    setState(() {
      _showCancelButton = !widget.controller.draggingNotifier.value &&
          widget.controller.isRecordingNotifier.value;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.controller.keepSliderNotifier.value) {
      return const SizedBox();
    }

    return AnimatedBuilder(
      animation: widget.animation,
      builder: (context, _) {
        return Positioned(
          left: widget.animation.value.toDouble(),
          right: 0,
          top: 0,
          bottom: 0,
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(25),
              bottomLeft: Radius.circular(25),
            ),
            child: ColoredBox(
              color: Theme.of(context)
                  .extension<MoxxyThemeData>()!
                  .conversationTextFieldColor,
              child: UnconstrainedBox(
                child: SizedBox(
                  width: getTextFieldWidth(context),
                  height: noTextTextFieldHeight,
                  child: Row(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 16),
                          child: TimerWidget(
                            controller: widget.controller.timerController,
                          ),
                        ),
                      ),
                      if (widget.controller.draggingNotifier.value)
                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: Icon(
                            Icons.chevron_left,
                            color: Colors.white,
                          ),
                        ),
                      if (widget.controller.draggingNotifier.value)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Text(
                            t.pages.conversation.voiceRecording.dragToCancel,
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      Expanded(
                        child: AnimatedOpacity(
                          opacity: _showCancelButton ? 1 : 0,
                          duration: const Duration(milliseconds: 200),
                          child: Align(
                            child: TextButton(
                              onPressed: widget.controller.cancelRecording,
                              child: Text(
                                t.pages.conversation.voiceRecording.cancel,
                                style: const TextStyle(
                                  color: Colors.red,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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
