import 'dart:math';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_vibrate/flutter_vibrate.dart';
import 'package:moxxyv2/shared/helpers.dart';
import 'package:moxxyv2/ui/bloc/conversation_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/ui/widgets/chat/media/media.dart';
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
  //bool _recording = false;
  //Offset _touchedPosition = Offset.zero;
  
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
                            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                            textColor: _getTextColor(context),
                            enableBoxShadow: true,
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
                                        showNotImplementedDialog('stickers', context);
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
                                        //print('Määäääh');
                                      },
                                    ),
                                    _TextFieldIconButton(
                                      Icons.photo_camera,
                                      () {
                                        //print('Määäääh');
                                      },
                                    ),
                                    _TextFieldIconButton(
                                      Icons.image,
                                      () {
                                        //print('Määäääh');
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
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          // NOTE: https://stackoverflow.com/a/52786741
                          //       Thank you kind sir
                          child: SizedBox(
                            height: 45,
                            width: 45,
                            child: FittedBox(
                              child: GestureDetector(
                                onTap: () {
                                  switch (state.sendButtonState) {
                                    case SendButtonState.audio: return;
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
                                onLongPressStart: (d) {
                                  if (state.sendButtonState != SendButtonState.audio) return;
                                  
                                  Vibrate.feedback(FeedbackType.heavy);
                                  //print('Start');
                                },
                                onLongPressEnd: (d) {
                                  if (state.sendButtonState != SendButtonState.audio) return;

                                  Vibrate.feedback(FeedbackType.heavy);
                                  //print('Done');
                                },
                                child: FloatingActionButton(
                                  onPressed: null,
                                  child: Icon(
                                    _getSendButtonIcon(state),
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        )
                      ],
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

        Positioned(
          // <dx|dy> - final size of circle / 2
          //top: _touchedPosition.dy - 100,
          //right: _touchedPosition.dx,
          bottom: -70,
          right: -15,
          child: IgnorePointer(
            child: AnimatedScale(
              duration: const Duration(milliseconds: 300),
              //scale: _recording ? 1 : 0,
              scale: 0,
              child: SizedBox(
                width: 200,
                height: 200,
                child: DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.red.shade600,
                  borderRadius: BorderRadius.circular(140),
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
