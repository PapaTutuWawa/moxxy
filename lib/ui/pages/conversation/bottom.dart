import 'dart:math';
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
import 'package:moxxyv2/ui/widgets/combined_picker.dart';
import 'package:moxxyv2/ui/widgets/textfield.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class _TextFieldIconButton extends StatelessWidget {
  const _TextFieldIconButton(this.icon, this.onTap);
  final void Function() onTap;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Icon(
          icon,
          size: 24,
          color: primaryColor,
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
    super.key,
  });

  final KeyboardReplacerController keyboardController;

  final BidirectionalConversationController conversationController;

  final TabController tabController;

  final ValueNotifier<bool> speedDialValueNotifier;

  final bool isEncrypted;

  @override
  ConversationInputState createState() => ConversationInputState();
}

class ConversationInputState extends State<ConversationInput> {
  final FocusNode _textfieldFocusNode = FocusNode();

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
                  false,
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
                    focusNode: _textfieldFocusNode,
                    //shouldSummonKeyboard: () => !snapshot.data!.pickerVisible,
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: _TextFieldIconButton(
                        snapshot.data!.pickerVisible
                            ? Icons.keyboard
                            : (widget.tabController.index == 0
                                ? Icons.insert_emoticon
                                : PhosphorIcons.stickerBold),
                        () {
                          widget.keyboardController
                              .toggleWidget(context, _textfieldFocusNode);
                          widget.conversationController
                              .togglePickerVisibility(true);
                        },
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

class ConversationBottomRow extends StatefulWidget {
  const ConversationBottomRow(
    this.tabController,
    this.focusNode,
    this.conversationController,
    this.speedDialValueNotifier, {
    super.key,
  });
  final TabController tabController;
  final FocusNode focusNode;
  final ValueNotifier<bool> speedDialValueNotifier;
  final BidirectionalConversationController conversationController;

  @override
  ConversationBottomRowState createState() => ConversationBottomRowState();
}

class ConversationBottomRowState extends State<ConversationBottomRow> {
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

  IconData _getPickerIcon() {
    if (widget.tabController.index == 0) {
      return Icons.insert_emoticon;
    }

    return PhosphorIcons.stickerBold;
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          child: ColoredBox(
            color: Colors.transparent,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8),
                  child: BlocBuilder<ConversationBloc, ConversationState>(
                    buildWhen: (prev, next) =>
                        prev.isRecording != next.isRecording,
                    builder: (context, state) => Row(
                      children: [
                        Expanded(
                          child: StreamBuilder<TextFieldData>(
                            initialData: const TextFieldData(
                              true,
                              null,
                              false,
                            ),
                            stream: widget
                                .conversationController.textFieldDataStream,
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
                                controller: widget
                                    .conversationController.textController,
                                topWidget: snapshot.data!.quotedMessage != null
                                    ? buildQuoteMessageWidget(
                                        snapshot.data!.quotedMessage!,
                                        isSent(
                                          snapshot.data!.quotedMessage!,
                                          GetIt.I.get<UIDataService>().ownJid!,
                                        ),
                                        textfieldQuotedMessageRadius,
                                        textfieldQuotedMessageRadius,
                                        resetQuote: widget
                                            .conversationController.removeQuote,
                                      )
                                    : null,
                                focusNode: widget.focusNode,
                                shouldSummonKeyboard: () =>
                                    !snapshot.data!.pickerVisible,
                                prefixIcon: IntrinsicWidth(
                                  child: Row(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(left: 8),
                                        child: _TextFieldIconButton(
                                          snapshot.data!.pickerVisible
                                              ? Icons.keyboard
                                              : _getPickerIcon(),
                                          () {
                                            widget.conversationController
                                                .togglePickerVisibility(true);
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                prefixIconConstraints: const BoxConstraints(
                                  minWidth: 24,
                                  minHeight: 24,
                                ),
                                suffixIcon: snapshot.data!.isBodyEmpty &&
                                        snapshot.data!.quotedMessage == null
                                    ? IntrinsicWidth(
                                        child: Row(
                                          children: const [
                                            Padding(
                                              padding:
                                                  EdgeInsets.only(right: 8),
                                              child: _TextFieldRecordButton(),
                                            ),
                                          ],
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
                          padding: const EdgeInsets.only(left: 8),
                          child: AnimatedOpacity(
                            opacity: state.isRecording ? 0 : 1,
                            duration: const Duration(milliseconds: 150),
                            child: IgnorePointer(
                              ignoring: state.isRecording,
                              child: SizedBox(
                                height: 45,
                                width: 45,
                                child: StreamBuilder<SendButtonState>(
                                  initialData: defaultSendButtonState,
                                  stream: widget
                                      .conversationController.sendButtonStream,
                                  builder: (context, snapshot) {
                                    return SpeedDial(
                                      icon: _getSendButtonIcon(snapshot.data!),
                                      backgroundColor: primaryColor,
                                      foregroundColor: Colors.white,
                                      children: [
                                        SpeedDialChild(
                                          child: const Icon(Icons.image),
                                          onTap: () {
                                            context
                                                .read<ConversationBloc>()
                                                .add(
                                                  ImagePickerRequestedEvent(),
                                                );
                                          },
                                          backgroundColor: primaryColor,
                                          foregroundColor: Colors.white,
                                          label:
                                              t.pages.conversation.sendImages,
                                        ),
                                        SpeedDialChild(
                                          child: const Icon(Icons.file_present),
                                          onTap: () {
                                            context
                                                .read<ConversationBloc>()
                                                .add(
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
                                          label:
                                              t.pages.conversation.takePhotos,
                                        ),
                                      ],
                                      openCloseDial:
                                          widget.speedDialValueNotifier,
                                      onPress: () {
                                        switch (snapshot.data!) {
                                          case SendButtonState.cancelCorrection:
                                            widget.conversationController
                                                .endMessageEditing();
                                            return;
                                          case SendButtonState.send:
                                            widget.conversationController
                                                .sendMessage(
                                              state.conversation!.encrypted,
                                            );
                                            return;
                                          case SendButtonState.multi:
                                            widget.speedDialValueNotifier
                                                    .value =
                                                !widget.speedDialValueNotifier
                                                    .value;
                                            return;
                                        }
                                      },
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                StreamBuilder<bool>(
                  initialData: false,
                  stream: widget.conversationController.pickerVisibleStream,
                  builder: (context, snapshot) => Offstage(
                    offstage: !snapshot.data!,
                    child: CombinedPicker(
                      tabController: widget.tabController,
                      onEmojiTapped: (emoji) {
                        final selection = widget
                            .conversationController.textController.selection;
                        final baseOffset = max(selection.baseOffset, 0);
                        final extentOffset = max(selection.extentOffset, 0);
                        final prefix = widget.conversationController.messageBody
                            .substring(0, baseOffset);
                        final suffix = widget.conversationController.messageBody
                            .substring(extentOffset);
                        final newText = '$prefix${emoji.emoji}$suffix';
                        final newValue =
                            baseOffset + emoji.emoji.codeUnits.length;
                        widget.conversationController.textController
                          ..text = newText
                          ..selection = TextSelection(
                            baseOffset: newValue,
                            extentOffset: newValue,
                          );
                      },
                      onBackspaceTapped: () {
                        // Taken from https://github.com/Fintasys/emoji_picker_flutter/blob/master/lib/src/emoji_picker.dart#L183
                        final text = widget.conversationController.messageBody;
                        final selection = widget
                            .conversationController.textController.selection;
                        final cursorPosition = widget.conversationController
                            .textController.selection.base.offset;

                        if (cursorPosition < 0) {
                          return;
                        }

                        final newTextBeforeCursor = selection
                            .textBefore(text)
                            .characters
                            .skipLast(1)
                            .toString();

                        widget.conversationController.textController
                          ..text = newTextBeforeCursor
                          ..selection = TextSelection.fromPosition(
                            TextPosition(offset: newTextBeforeCursor.length),
                          );
                      },
                      onStickerTapped: (sticker, pack) {
                        widget.conversationController.sendSticker(
                          sticker,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          left: 8,
          bottom: 8,
          right: 61,
          child: BlocBuilder<ConversationBloc, ConversationState>(
            buildWhen: (prev, next) => prev.isRecording != next.isRecording,
            builder: (context, state) {
              return AnimatedOpacity(
                opacity: state.isRecording ? 1 : 0,
                duration: const Duration(milliseconds: 300),
                child: IgnorePointer(
                  ignoring: !state.isRecording,
                  child: SizedBox(
                    height: textFieldFontSizeConversation + 2 * 12 + 2,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius:
                            BorderRadius.circular(textfieldRadiusConversation),
                        color: Theme.of(context).scaffoldBackgroundColor,
                      ),
                      // NOTE: We use a comprehension here so that the widget gets
                      //       created and destroyed to prevent the timer from running
                      //       until the user closes the page.
                      child: state.isRecording
                          ? const Align(
                              alignment: Alignment.centerLeft,
                              child: Padding(
                                padding: EdgeInsets.only(left: 16),
                                child: TimerWidget(),
                              ),
                            )
                          : null,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
