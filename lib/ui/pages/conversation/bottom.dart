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
                    : PhosphorIcons.stickerBold),
            size: 24,
            color: primaryColor,
          ),
        ),
      ),
    );
  }
}

class _TextFieldRecordButton extends StatelessWidget {
  const _TextFieldRecordButton();

  @override
  Widget build(BuildContext context) {
    return LongPressDraggable<int>(
      data: 1,
      axis: Axis.vertical,
      onDragStarted: () {
        Vibrate.feedback(FeedbackType.heavy);
        context.read<ConversationBloc>().add(
              SendButtonDragStartedEvent(),
            );
      },
      onDraggableCanceled: (_, __) {
        Vibrate.feedback(FeedbackType.heavy);
        context.read<ConversationBloc>().add(
              SendButtonDragEndedEvent(),
            );
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
        child: Row(
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
                    controller: widget.conversationController.textController,
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
                        ? const Padding(
                            padding: EdgeInsets.only(right: 8),
                            child: _TextFieldRecordButton(),
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
                  builder: (context, snapshot) => SpeedDial(
                    icon: _getSendButtonIcon(snapshot.data!),
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
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
                          widget.conversationController.endMessageEditing();
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
                      }
                    },
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
