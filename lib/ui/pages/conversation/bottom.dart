import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/ui/bloc/conversation_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/controller/conversation_controller.dart';
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/ui/pages/conversation/blink.dart';
import 'package:moxxyv2/ui/pages/conversation/keyboard_dodging.dart';
import 'package:moxxyv2/ui/pages/conversation/timer.dart';
import 'package:moxxyv2/ui/service/data.dart';
import 'package:moxxyv2/ui/theme.dart';
import 'package:moxxyv2/ui/widgets/chat/message.dart';
import 'package:moxxyv2/ui/widgets/textfield.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class _TextFieldIconButton extends StatelessWidget {
  const _TextFieldIconButton({
    required this.keyboardController,
    required this.tabController,
    required this.textfieldFocusNode,
  });

  final KeyboardReplacerController keyboardController;
  final TabController tabController;

  final FocusNode textfieldFocusNode;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        keyboardController.toggleWidget(context, textfieldFocusNode);
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: StreamBuilder<KeyboardReplacerData>(
          stream: keyboardController.stream,
          initialData: keyboardController.currentData,
          builder: (context, snapshot) => Icon(
            snapshot.data!.showWidget
                ? Icons.keyboard
                : (tabController.index == 0
                    ? Icons.insert_emoticon
                    : PhosphorIcons.thin.sticker),
            size: 24,
            color: primaryColor,
          ),
        ),
      ),
    );
  }
}

class _TextFieldRecordButton extends StatelessWidget {
  const _TextFieldRecordButton({
    required this.conversationController,
    required this.keyboardController,
  });

  final BidirectionalConversationController conversationController;
  final KeyboardReplacerController keyboardController;

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<int>(
      data: 1,
      axis: Axis.vertical,
      onDragStarted: () {
        Vibrate.feedback(FeedbackType.heavy);

        conversationController.startAudioMessageRecording();
        keyboardController.hideWidget();
        dismissSoftKeyboard(context);
      },
      onDraggableCanceled: (_, __) {
        Vibrate.feedback(FeedbackType.heavy);

        conversationController.endAudioMessageRecording();
      },
      childWhenDragging: const SizedBox(),
      feedback: SizedBox(
        width: 45,
        height: 45,
        child: FloatingActionButton(
          onPressed: null,
          heroTag: 'fabDragged',
          backgroundColor: Colors.red.shade600,
          child: BlinkingIcon(
            icon: Icons.mic,
            duration: const Duration(milliseconds: 600),
            start: Colors.white,
            end: Colors.red.shade600,
          ),
        ),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: Icon(
          Icons.mic,
          size: 24,
          color: primaryColor,
        ),
      ),
    );
  }
}

class ConversationInput extends StatefulWidget {
  const ConversationInput({
    required this.keyboardController,
    required this.conversationController,
    required this.tabController,
    required this.speedDialValueNotifier,
    required this.isEncrypted,
    required this.textfieldFocusNode,
    super.key,
  });

  final KeyboardReplacerController keyboardController;

  final BidirectionalConversationController conversationController;

  final TabController tabController;

  final ValueNotifier<bool> speedDialValueNotifier;

  final bool isEncrypted;

  final FocusNode textfieldFocusNode;

  @override
  ConversationInputState createState() => ConversationInputState();
}

class ConversationInputState extends State<ConversationInput> {
  IconData _getSendButtonIcon(SendButtonState state) {
    switch (state) {
      case SendButtonState.hidden:
      case SendButtonState.multi:
        return Icons.add;
      case SendButtonState.send:
        return Icons.send;
      case SendButtonState.cancelCorrection:
        return Icons.clear;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black45,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Stack(
          children: [
            Row(
              children: [
                Expanded(
                  child: StreamBuilder<TextFieldData>(
                    initialData: const TextFieldData(
                      true,
                      null,
                    ),
                    stream: widget.conversationController.textFieldDataStream,
                    builder: (context, snapshot) {
                      return CustomTextField(
                        backgroundColor: Theme.of(context)
                            .extension<MoxxyThemeData>()!
                            .conversationTextFieldColor,
                        textColor: Theme.of(context)
                            .extension<MoxxyThemeData>()!
                            .conversationTextFieldTextColor,
                        maxLines: 5,
                        hintText: t.pages.conversation.messageHint,
                        hintTextColor: Theme.of(context)
                            .extension<MoxxyThemeData>()!
                            .conversationTextFieldHintTextColor,
                        isDense: true,
                        contentPadding: textfieldPaddingConversation,
                        fontSize: textFieldFontSizeConversation,
                        cornerRadius: textfieldRadiusConversation,
                        controller:
                            widget.conversationController.textController,
                        topWidget: snapshot.data!.quotedMessage != null
                            ? buildQuoteMessageWidget(
                                snapshot.data!.quotedMessage!,
                                isSent(
                                  snapshot.data!.quotedMessage!,
                                  GetIt.I.get<UIDataService>().ownJid!,
                                ),
                                textfieldQuotedMessageRadius,
                                textfieldQuotedMessageRadius,
                                resetQuote:
                                    widget.conversationController.removeQuote,
                              )
                            : null,
                        focusNode: widget.textfieldFocusNode,
                        //shouldSummonKeyboard: () => !snapshot.data!.pickerVisible,
                        prefixIcon: Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _TextFieldIconButton(
                            keyboardController: widget.keyboardController,
                            tabController: widget.tabController,
                            textfieldFocusNode: widget.textfieldFocusNode,
                          ),
                        ),
                        prefixIconConstraints: const BoxConstraints(
                          minWidth: 24,
                          minHeight: 24,
                        ),
                        suffixIcon: snapshot.data!.isBodyEmpty &&
                                snapshot.data!.quotedMessage == null
                            ? Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: _TextFieldRecordButton(
                                  conversationController:
                                      widget.conversationController,
                                  keyboardController: widget.keyboardController,
                                ),
                              )
                            : null,
                        suffixIconConstraints: const BoxConstraints(
                          minWidth: 24,
                          minHeight: 24,
                        ),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: SizedBox(
                    width: 45,
                    height: 45,
                    child: StreamBuilder<SendButtonState>(
                      initialData: defaultSendButtonState,
                      stream: widget.conversationController.sendButtonStream,
                      builder: (context, snapshot) => IgnorePointer(
                        ignoring: snapshot.data! == SendButtonState.hidden,
                        child: AnimatedOpacity(
                          opacity:
                              snapshot.data! == SendButtonState.hidden ? 0 : 1,
                          duration: const Duration(milliseconds: 150),
                          child: SpeedDial(
                            icon: _getSendButtonIcon(snapshot.data!),
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,

                            // Adjust to Material3's specifications
                            // (Thanks https://github.com/darioielardi/flutter_speed_dial/issues/279#issuecomment-1373002572)
                            shape: const RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.all(Radius.circular(16)),
                            ),
                            spacing: 16,
                            childMargin: EdgeInsets.zero,
                            childPadding: const EdgeInsets.all(8),

                            children: [
                              SpeedDialChild(
                                child: const Icon(Icons.image),
                                onTap: () {
                                  context.read<ConversationBloc>().add(
                                        ImagePickerRequestedEvent(),
                                      );
                                },
                                backgroundColor: primaryColor,
                                foregroundColor: Colors.white,
                                label: t.pages.conversation.sendImages,
                              ),
                              SpeedDialChild(
                                child: const Icon(Icons.file_present),
                                onTap: () {
                                  context.read<ConversationBloc>().add(
                                        FilePickerRequestedEvent(),
                                      );
                                },
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
                                  widget.conversationController
                                      .endMessageEditing();
                                  return;
                                case SendButtonState.send:
                                  widget.conversationController.sendMessage(
                                    widget.isEncrypted,
                                  );
                                  return;
                                case SendButtonState.multi:
                                  widget.speedDialValueNotifier.value =
                                      !widget.speedDialValueNotifier.value;
                                  return;
                                case SendButtonState.hidden:
                                  return;
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Positioned(
              top: 0,
              bottom: 0,
              left: 0,
              right: 45 + 16,
              child: StreamBuilder<RecordingData>(
                initialData: const RecordingData(
                  false,
                  false,
                ),
                stream:
                    widget.conversationController.recordingAudioMessageStream,
                builder: (context, snapshot) => IgnorePointer(
                  ignoring: !snapshot.data!.isRecording,
                  child: AnimatedOpacity(
                    opacity: snapshot.data!.isRecording ? 1 : 0,
                    duration: const Duration(milliseconds: 150),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Theme.of(context)
                            .extension<MoxxyThemeData>()!
                            .conversationTextFieldColor,
                        borderRadius:
                            BorderRadius.circular(textfieldRadiusConversation),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(left: 16),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: snapshot.data!.isRecording
                              ? const TimerWidget()
                              : const SizedBox(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
