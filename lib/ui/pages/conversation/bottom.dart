import 'package:emoji_picker_flutter/emoji_picker_flutter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:moxxyv2/ui/bloc/conversation_bloc.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/ui/widgets/chat/media/media.dart';
import 'package:moxxyv2/ui/widgets/textfield.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ConversationBottomRow extends StatelessWidget {

  const ConversationBottomRow(this.controller, this.isSpeedDialOpen, {Key? key}) : super(key: key);
  final TextEditingController controller;
  final ValueNotifier<bool> isSpeedDialOpen;

  Color _getTextColor(BuildContext context) {
    // TODO(Unknown): Work on the colors
    if (MediaQuery.of(context).platformBrightness == Brightness.dark) {
      return Colors.white;
    }

    return Colors.black;
  }
  
  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color.fromRGBO(0, 0, 0, 0),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8),
            child: BlocBuilder<ConversationBloc, ConversationState>(
              buildWhen: (prev, next) => prev.showSendButton != next.showSendButton || prev.quotedMessage != next.quotedMessage || prev.emojiPickerVisible != next.emojiPickerVisible || prev.messageText != next.messageText,
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
                      controller: controller,
                      topWidget: state.quotedMessage != null ? buildQuoteMessageWidget(
                        state.quotedMessage!,
                        resetQuote: () => context.read<ConversationBloc>().add(QuoteRemovedEvent()),
                      ) : null,
                      shouldSummonKeyboard: () => !state.emojiPickerVisible,
                      prefixIcon: IntrinsicWidth(
                        child: Row(
                          children: [
                            InkWell(
                              child: const Padding(
                                padding: EdgeInsets.symmetric(horizontal: 8),
                                child: Icon(
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
                              visible: state.messageText.isEmpty,
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
                        child: SpeedDial(
                          icon: state.showSendButton ? Icons.send : Icons.add,
                          curve: Curves.bounceInOut,
                          backgroundColor: primaryColor,
                          // TODO(Unknown): Theme dependent?
                          foregroundColor: Colors.white,
                          openCloseDial: isSpeedDialOpen,
                          onPress: () {
                            if (state.showSendButton) {
                              context.read<ConversationBloc>().add(MessageSentEvent());
                              controller.text = '';
                            } else {
                              isSpeedDialOpen.value = true;
                            }
                          },
                          children: [
                            SpeedDialChild(
                              child: const Icon(Icons.image),
                              onTap: () {
                                context.read<ConversationBloc>().add(ImagePickerRequestedEvent());
                              },
                              backgroundColor: primaryColor,
                              // TODO(Unknown): Theme dependent?
                              foregroundColor: Colors.white,
                              label: 'Send Images',
                            ),
                            SpeedDialChild(
                              child: const Icon(Icons.photo_camera),
                              onTap: () {
                                showNotImplementedDialog('taking photos', context);
                              },
                              backgroundColor: primaryColor,
                              // TODO(Unknown): Theme dependent?
                              foregroundColor: Colors.white,
                              label: 'Take photo',
                            ),
                            SpeedDialChild(
                              child: const Icon(Icons.attach_file),
                              onTap: () {
                                context.read<ConversationBloc>().add(FilePickerRequestedEvent());
                              },
                              backgroundColor: primaryColor,
                              // TODO(Unknown): Theme dependent?
                              foregroundColor: Colors.white,
                              label: 'Send files',
                            )
                          ],
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
                    // TODO(PapaTutuWawa): This needs to keep the cursor in mind
                    // TODO(PapaTutuWawa): Also see here https://github.com/flutter/flutter/issues/16863#issuecomment-854340383
                    final bloc = context.read<ConversationBloc>();

                    
                    final selection = controller.selection;
                    final prefix = bloc.state.messageText.substring(0, selection.baseOffset);
                    final suffix = bloc.state.messageText.substring(selection.extentOffset);
                    final newText = '$prefix${emoji.emoji}$suffix';
                    final newValue = selection.baseOffset + emoji.emoji.codeUnits.length;
                    bloc.add(MessageTextChangedEvent(newText));
                    controller
                      ..text = newText
                      ..selection = TextSelection(
                        baseOffset: newValue,
                        extentOffset: newValue,
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
    );
  }
}
