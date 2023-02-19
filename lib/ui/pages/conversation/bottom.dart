import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/ui/bloc/conversation_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/controller/conversation_controller.dart';
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/ui/pages/conversation/blink.dart';
import 'package:moxxyv2/ui/pages/conversation/timer.dart';
import 'package:moxxyv2/ui/service/data.dart';
import 'package:moxxyv2/ui/theme.dart';
import 'package:moxxyv2/ui/widgets/chat/media/media.dart';
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

class ConversationBottomRow extends StatefulWidget {
  const ConversationBottomRow(
    this.tabController,
    this.focusNode,
    this.conversationController,
    this.speedDialValueNotifier, {
      super.key,
    }
  );
  final TabController tabController;
  final FocusNode focusNode;
  final ValueNotifier<bool> speedDialValueNotifier;
  final BidirectionalConversationController conversationController;

  @override
  ConversationBottomRowState createState() => ConversationBottomRowState();
}

class ConversationBottomRowState extends State<ConversationBottomRow> {
  late StreamSubscription<bool> _keyboardVisibilitySubscription;
  
  @override
  void initState() {
    super.initState();

    _keyboardVisibilitySubscription = KeyboardVisibilityController().onChange.listen(
      _onKeyboardVisibilityChanged,
    );
  }

  @override
  void dispose() {
    _keyboardVisibilitySubscription.cancel();
    super.dispose();
  }

  void _onKeyboardVisibilityChanged(bool visible) {
    GetIt.I.get<ConversationBloc>().add(
      SoftKeyboardVisibilityChanged(visible),
    );
  }
  
  IconData _getSendButtonIcon(SendButtonState state) {
    switch (state) {
      case SendButtonState.multi: return Icons.add;
      case SendButtonState.send: return Icons.send;
      case SendButtonState.cancelCorrection: return Icons.clear;
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
                    buildWhen: (prev, next) => prev.sendButtonState != next.sendButtonState || prev.quotedMessage != next.quotedMessage || prev.pickerVisible != next.pickerVisible || prev.messageText != next.messageText || prev.messageEditing != next.messageEditing || prev.messageEditingOriginalBody != next.messageEditingOriginalBody || prev.isRecording != next.isRecording,
                    builder: (context, state) => Row(
                      children: [
                        Expanded(
                          child: StreamBuilder<TextFieldData>(
                            initialData: TextFieldData(
                              true,
                              null,
                            ),
                            stream: widget.conversationController.textFieldDataStream,
                            builder: (context, snapshot) {
                              return CustomTextField(
                                backgroundColor: Theme
                                  .of(context)
                                  .extension<MoxxyThemeData>()!
                                  .conversationTextFieldColor,
                                textColor: Theme
                                  .of(context)
                                  .extension<MoxxyThemeData>()!
                                  .conversationTextFieldTextColor,
                                maxLines: 5,
                                hintText: t.pages.conversation.messageHint,
                                hintTextColor: Theme
                                  .of(context)
                                  .extension<MoxxyThemeData>()!
                                  .conversationTextFieldHintTextColor,
                                isDense: true,
                                contentPadding: textfieldPaddingConversation,
                                fontSize: textFieldFontSizeConversation,
                                cornerRadius: textfieldRadiusConversation,
                                controller: widget.conversationController.textController,
                                topWidget: snapshot.data!.quotedMessage != null ?
                                  buildQuoteMessageWidget(
                                    snapshot.data!.quotedMessage!,
                                    isSent(
                                      snapshot.data!.quotedMessage!,
                                      GetIt.I.get<UIDataService>().ownJid!,
                                    ),
                                    resetQuote: widget.conversationController.removeQuote,
                                  ) :
                                  null,
                                focusNode: widget.focusNode,
                                shouldSummonKeyboard: () => !state.pickerVisible,
                                prefixIcon: IntrinsicWidth(
                                  child: Row(
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.only(left: 8),
                                        child: _TextFieldIconButton(
                                          state.pickerVisible ? 
                                            Icons.keyboard :
                                            _getPickerIcon(),
                                          () {
                                            context.read<ConversationBloc>().add(
                                              PickerToggledEvent(),
                                            );
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
                                suffixIcon: snapshot.data!.isBodyEmpty && snapshot.data!.quotedMessage == null ?
                                  IntrinsicWidth(
                                    child: Row(
                                      children: const [
                                        Padding(
                                          padding: EdgeInsets.only(right: 8),
                                          child: _TextFieldRecordButton(),
                                        ),
                                      ],
                                    ),
                                  ) :
                                  null,
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
                                  stream: widget.conversationController.sendButtonStream,
                                  builder: (context, snapshot) {
                                    return SpeedDial(
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
                                            showNotImplementedDialog('taking photos', context);
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
                                            state.conversation!.encrypted,
                                          );
                                          return;
                                          case SendButtonState.multi:
                                          widget.speedDialValueNotifier.value = !widget.speedDialValueNotifier.value;
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

                BlocBuilder<ConversationBloc, ConversationState>(
                  buildWhen: (prev, next) => prev.pickerVisible != next.pickerVisible,
                  builder: (context, state) => Offstage(
                    offstage: !state.pickerVisible,
                    child: CombinedPicker(
                      tabController: widget.tabController,
                      onEmojiTapped: (emoji) {
                        final bloc = context.read<ConversationBloc>();
                        final selection = widget.conversationController.textController.selection;
                        final baseOffset = max(selection.baseOffset, 0);
                        final extentOffset = max(selection.extentOffset, 0);
                        final prefix = bloc.state.messageText.substring(0, baseOffset);
                        final suffix = bloc.state.messageText.substring(extentOffset);
                        final newText = '$prefix${emoji.emoji}$suffix';
                        final newValue = baseOffset + emoji.emoji.codeUnits.length;
                        bloc.add(MessageTextChangedEvent(newText));
                        widget.conversationController.textController
                          ..text = newText
                          ..selection = TextSelection(
                            baseOffset: newValue,
                            extentOffset: newValue,
                          );
                      },
                      onBackspaceTapped: () {
                        // Taken from https://github.com/Fintasys/emoji_picker_flutter/blob/master/lib/src/emoji_picker.dart#L183
                        final bloc = context.read<ConversationBloc>();
                        final text = bloc.state.messageText;
                        final selection = widget.conversationController.textController.selection;
                        final cursorPosition = widget.conversationController.textController.selection.base.offset;
 
                        if (cursorPosition < 0) {
                          return;
                        }
 
                        final newTextBeforeCursor = selection
                        .textBefore(text).characters
                        .skipLast(1)
                        .toString();
 
                        bloc.add(MessageTextChangedEvent(newTextBeforeCursor));
                        widget.conversationController.textController
                          ..text = newTextBeforeCursor
                          ..selection = TextSelection.fromPosition(
                            TextPosition(offset: newTextBeforeCursor.length),
                          );
                      },
                      onStickerTapped: (sticker, pack) {
                        context.read<ConversationBloc>().add(
                          StickerSentEvent(
                            pack.id,
                            sticker.hashKey,
                          ),
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
                        borderRadius: BorderRadius.circular(textfieldRadiusConversation),
                        color: Theme.of(context).scaffoldBackgroundColor,
                      ),
                      // NOTE: We use a comprehension here so that the widget gets
                      //       created and destroyed to prevent the timer from running
                      //       until the user closes the page.
                      child: state.isRecording ?
                        const Align(
                          alignment: Alignment.centerLeft,
                          child: Padding(
                            padding: EdgeInsets.only(left: 16),
                            child: TimerWidget(),
                          ),
                        ) :
                        null,
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
