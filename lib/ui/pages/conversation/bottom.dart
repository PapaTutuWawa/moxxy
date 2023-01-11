import 'dart:async';
import 'dart:math';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get_it/get_it.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/ui/bloc/conversation_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/ui/pages/conversation/blink.dart';
import 'package:moxxyv2/ui/pages/conversation/timer.dart';
import 'package:moxxyv2/ui/theme.dart';
import 'package:moxxyv2/ui/widgets/chat/media/media.dart';
import 'package:moxxyv2/ui/widgets/sticker_picker.dart';
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
          size: 20,
          color: primaryColor,
        ),
      ),
    );
  }
}

class ConversationBottomRow extends StatefulWidget {
  const ConversationBottomRow(
    this.controller,
    this.focusNode, {
      super.key,
    }
  );
  final TextEditingController controller;
  final FocusNode focusNode;

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
  
  Color _getTextColor(BuildContext context) {
    // TODO(Unknown): Work on the colors
    if (MediaQuery.of(context).platformBrightness == Brightness.dark) {
      return Colors.white;
    }

    return Colors.black;
  }

  IconData _getSendButtonIcon(ConversationState state) {
    switch (state.sendButtonState) {
      case SendButtonState.audio: return Icons.mic;
      case SendButtonState.send: return Icons.send;
      case SendButtonState.cancelCorrection: return Icons.clear;
    }
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
                    buildWhen: (prev, next) => prev.sendButtonState != next.sendButtonState || prev.quotedMessage != next.quotedMessage || prev.emojiPickerVisible != next.emojiPickerVisible || prev.messageText != next.messageText || prev.messageEditing != next.messageEditing || prev.messageEditingOriginalBody != next.messageEditingOriginalBody,
                    builder: (context, state) => Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            // TODO(Unknown): Work on the colors
                            backgroundColor: Theme.of(context).extension<MoxxyThemeData>()!.conversationTextFieldColor,
                            textColor: _getTextColor(context),
                            maxLines: 5,
                            hintText: 'Send a message...',
                            isDense: true,
                            onChanged: (value) {
                              context.read<ConversationBloc>().add(
                                MessageTextChangedEvent(value),
                              );
                            },
                            contentPadding: textfieldPaddingConversation,
                            cornerRadius: textfieldRadiusConversation,
                            controller: widget.controller,
                            topWidget: state.quotedMessage != null ? buildQuoteMessageWidget(
                              state.quotedMessage!,
                              isSent(state.quotedMessage!, state.jid),
                              resetQuote: () => context.read<ConversationBloc>().add(QuoteRemovedEvent()),
                            ) : null,
                            focusNode: widget.focusNode,
                            shouldSummonKeyboard: () => !state.emojiPickerVisible,
                            prefixIcon: IntrinsicWidth(
                              child: Row(
                                children: [
                                  InkWell(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 8),
                                      child: Icon(
                                        state.emojiPickerVisible ? 
                                          Icons.keyboard :
                                          Icons.insert_emoticon,
                                        color: primaryColor,
                                        size: 24,
                                      ),
                                    ),
                                    onTap: () {
                                      context.read<ConversationBloc>().add(EmojiPickerToggledEvent());
                                    },
                                  ),
                                  Visibility(
                                    visible: state.messageText.isEmpty && state.quotedMessage == null,
                                    child: InkWell(
                                      child: const Padding(
                                        padding: EdgeInsets.only(right: 8),
                                        child: Icon(
                                          PhosphorIcons.stickerBold,
                                          size: 24,
                                          color: primaryColor,
                                        ),
                                      ),
                                      onTap: () {
                                        context.read<ConversationBloc>().add(
                                          StickerPickerToggledEvent(),
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
                            suffixIcon: state.messageText.isEmpty && state.quotedMessage == null ?
                              IntrinsicWidth(
                                child: Row(
                                  children: [
                                    _TextFieldIconButton(
                                      Icons.attach_file,
                                      () {
                                        context.read<ConversationBloc>().add(
                                          FilePickerRequestedEvent(),
                                        );
                                      },
                                    ),
                                    _TextFieldIconButton(
                                      Icons.photo_camera,
                                      () {
                                        showNotImplementedDialog(
                                          'taking photos',
                                          context,
                                        );
                                      },
                                    ),
                                    _TextFieldIconButton(
                                      Icons.image,
                                      () {
                                        context.read<ConversationBloc>().add(
                                          ImagePickerRequestedEvent(),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ) :
                              null,
                            suffixIconConstraints: const BoxConstraints(
                              minWidth: 24,
                              minHeight: 24,
                            ),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(left: 8),
                          child: SizedBox(
                            height: 45,
                            width: 45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                BlocBuilder<ConversationBloc, ConversationState>(
                  buildWhen: (prev, next) => prev.stickerPickerVisible != next.stickerPickerVisible,
                  builder: (context, state) => Offstage(
                    offstage: !state.stickerPickerVisible,
                    child: StickerPicker(
                      width: MediaQuery.of(context).size.width,
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

                BlocBuilder<ConversationBloc, ConversationState>(
                  buildWhen: (prev, next) => prev.emojiPickerVisible != next.emojiPickerVisible,
                  builder: (context, state) => Offstage(
                    offstage: !state.emojiPickerVisible,
                    child: SizedBox(
                      height: 250,
                      child: EmojiPicker(
                        onEmojiSelected: (_, emoji) {
                          final bloc = context.read<ConversationBloc>();
                          final selection = widget.controller.selection;
                          final baseOffset = max(selection.baseOffset, 0);
                          final extentOffset = max(selection.extentOffset, 0);
                          final prefix = bloc.state.messageText.substring(0, baseOffset);
                          final suffix = bloc.state.messageText.substring(extentOffset);
                          final newText = '$prefix${emoji.emoji}$suffix';
                          final newValue = baseOffset + emoji.emoji.codeUnits.length;
                          bloc.add(MessageTextChangedEvent(newText));
                          widget.controller
                            ..text = newText
                            ..selection = TextSelection(
                              baseOffset: newValue,
                              extentOffset: newValue,
                            );
                        },
                        onBackspacePressed: () {
                          // Taken from https://github.com/Fintasys/emoji_picker_flutter/blob/master/lib/src/emoji_picker.dart#L183
                          final bloc = context.read<ConversationBloc>();
                          final text = bloc.state.messageText;
                          final selection = widget.controller.selection;
                          final cursorPosition = widget.controller.selection.base.offset;

                          if (cursorPosition < 0) {
                            return;
                          }

                          final newTextBeforeCursor = selection
                          .textBefore(text).characters
                          .skipLast(1)
                          .toString();

                          bloc.add(MessageTextChangedEvent(newTextBeforeCursor));
                          widget.controller
                            ..text = newTextBeforeCursor
                            ..selection = TextSelection.fromPosition(
                              TextPosition(offset: newTextBeforeCursor.length),
                            );
                        },
                        config: Config(
                          bgColor: Theme.of(context).scaffoldBackgroundColor,
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
          buildWhen: (prev, next) => prev.sendButtonState != next.sendButtonState ||
            prev.isDragging != next.isDragging ||
            prev.isLocked != next.isLocked ||
            prev.emojiPickerVisible != next.emojiPickerVisible ||
            prev.stickerPickerVisible != next.stickerPickerVisible,
          builder: (context, state) {
            return Positioned(
              right: 8,
              bottom: state.emojiPickerVisible || state.stickerPickerVisible ?
                258 /* 8 (Regular padding) + 250 (Height of the pickers) */ :
                8,
              child: Visibility(
                visible: !state.isDragging && !state.isLocked,
                child: LongPressDraggable<int>(
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
                  feedback: SizedBox(
                    height: 45,
                    width: 45,
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
                  childWhenDragging: SizedBox(
                    height: 45,
                    width: 45,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Colors.grey,
                        borderRadius: BorderRadius.circular(45),
                      ),
                    ),
                  ),
                  child: SizedBox(
                    height: 45,
                    width: 45,
                    child: FloatingActionButton(
                      heroTag: 'fabRest',
                      onPressed: () {
                        switch (state.sendButtonState) {
                          case SendButtonState.audio:
                          Vibrate.feedback(FeedbackType.heavy);
                          Fluttertoast.showToast(
                            msg: t.warnings.conversation.holdForLonger,
                            gravity: ToastGravity.SNACKBAR,
                            toastLength: Toast.LENGTH_SHORT,
                          );
                          return;
                          case SendButtonState.cancelCorrection:
                          context.read<ConversationBloc>().add(
                            MessageEditCancelledEvent(),
                          );
                          widget.controller.text = '';
                          return;
                          case SendButtonState.send:
                          context.read<ConversationBloc>().add(
                            MessageSentEvent(),
                          );
                          widget.controller.text = '';
                          return;
                        }
                      },
                      child: Icon(
                        _getSendButtonIcon(state),
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),

        Positioned(
          left: 8,
          bottom: 11,
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
                    height: 38,
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
