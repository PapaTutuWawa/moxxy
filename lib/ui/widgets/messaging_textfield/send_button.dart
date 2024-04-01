import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/ui/bloc/conversation.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/controller/conversation_controller.dart';
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/ui/widgets/messaging_textfield/controller.dart';

class SendButton extends StatefulWidget {
  const SendButton({
    required this.controller,
    required this.conversationController,
    required this.speedDialValueNotifier,
    required this.isEncrypted,
    super.key,
  });

  final MobileMessagingTextFieldController controller;
  final BidirectionalConversationController conversationController;
  final ValueNotifier<bool> speedDialValueNotifier;
  final bool isEncrypted;

  @override
  SendButtonWidgetState createState() => SendButtonWidgetState();
}

class SendButtonWidgetState extends State<SendButton> {
  bool _showSpeedDial = true;

  @override
  void initState() {
    super.initState();

    widget.controller.draggingNotifier.addListener(_onValueChanged);
    widget.controller.lockedNotifier.addListener(_onValueChanged);
  }

  @override
  void dispose() {
    widget.controller.draggingNotifier.removeListener(_onValueChanged);
    widget.controller.lockedNotifier.removeListener(_onValueChanged);

    super.dispose();
  }

  void _onValueChanged() {
    setState(() {
      _showSpeedDial = !widget.controller.draggingNotifier.value ||
          !widget.controller.draggingNotifier.value &&
              widget.controller.lockedNotifier.value;
    });
  }

  IconData _getSendButtonIcon(SendButtonState state) {
    switch (state) {
      case SendButtonState.multi:
        return Icons.add;
      case SendButtonState.sendVoiceMessage:
      case SendButtonState.send:
        return Icons.send;
      case SendButtonState.cancelCorrection:
        return Icons.clear;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: _showSpeedDial ? 1 : 0,
      duration: const Duration(milliseconds: 200),
      child: IgnorePointer(
        ignoring: !_showSpeedDial,
        child: StreamBuilder<SendButtonState>(
          stream: widget.conversationController.sendButtonStream,
          initialData: defaultSendButtonState,
          builder: (context, snapshot) {
            return SpeedDial(
              icon: _getSendButtonIcon(snapshot.data!),
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              children: [
                SpeedDialChild(
                  child: const Icon(Icons.image),
                  onTap: context.read<ConversationCubit>().requestImagePicker,
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  label: t.pages.conversation.sendMedia,
                ),
                SpeedDialChild(
                  child: const Icon(Icons.file_present),
                  onTap: context.read<ConversationCubit>().requestFilePicker,
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  label: t.pages.conversation.sendFiles,
                ),
                SpeedDialChild(
                  child: const Icon(Icons.photo_camera),
                  onTap: () {
                    showNotImplementedDialog(
                      'taking photos',
                      context,
                    );
                  },
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  label: t.pages.conversation.takePhotos,
                ),
              ],
              openCloseDial: widget.speedDialValueNotifier,
              onPress: () {
                switch (snapshot.data!) {
                  case SendButtonState.cancelCorrection:
                    widget.conversationController.endMessageEditing();
                    return;
                  case SendButtonState.send:
                    widget.conversationController.sendMessage(
                      widget.isEncrypted,
                    );
                    return;
                  case SendButtonState.sendVoiceMessage:
                    widget.controller.endRecording();
                    return;
                  case SendButtonState.multi:
                    widget.speedDialValueNotifier.value =
                        !widget.speedDialValueNotifier.value;
                    return;
                }
              },
            );
          },
        ),
      ),
    );
  }
}
