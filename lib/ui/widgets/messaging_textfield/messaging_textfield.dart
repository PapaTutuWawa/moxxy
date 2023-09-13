import 'package:flutter/material.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/ui/constants.dart';
import 'package:moxxyv2/ui/controller/conversation_controller.dart';
import 'package:moxxyv2/ui/pages/conversation/keyboard_dodging.dart';
import 'package:moxxyv2/ui/theme.dart';
import 'package:moxxyv2/ui/widgets/messaging_textfield/record_icon.dart';
import 'package:moxxyv2/ui/widgets/messaging_textfield/send_button.dart';
import 'package:moxxyv2/ui/widgets/messaging_textfield/slider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class EmojiStickerPickerIcon extends StatelessWidget {
  const EmojiStickerPickerIcon({
    required this.keyboardController,
    required this.tabController,
    required this.textFieldFocusNode,
    super.key,
  });

  final KeyboardReplacerController keyboardController;
  final TabController tabController;
  final FocusNode textFieldFocusNode;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: StreamBuilder<KeyboardReplacerData>(
            stream: keyboardController.stream,
            initialData: keyboardController.currentData,
            builder: (context, snapshot) {
              return InkWell(
                onTap: () {
                  keyboardController.toggleWidget(context, textFieldFocusNode);
                },
                child: Icon(
                  snapshot.data!.showWidget
                      ? Icons.keyboard
                      : (tabController.index == 0
                          ? Icons.emoji_emotions
                          : PhosphorIcons.thin.sticker),
                  size: 24,
                  color: primaryColor,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class MobileMessagingTextField extends StatefulWidget {
  const MobileMessagingTextField({
    required this.conversationController,
    required this.textFieldFocusNode,
    required this.keyboardController,
    required this.tabController,
    required this.speedDialValueNotifier,
    required this.isEncrypted,
    super.key,
  });


  final FocusNode textFieldFocusNode;

  final BidirectionalConversationController conversationController;

  final KeyboardReplacerController keyboardController;

  final TabController tabController;

  final ValueNotifier<bool> speedDialValueNotifier;

  final bool isEncrypted;

  @override
  MobileMessagingTextFieldState createState() =>
      MobileMessagingTextFieldState();
}

class MobileMessagingTextFieldState extends State<MobileMessagingTextField>
    with TickerProviderStateMixin {
  late AnimationController _backgroundSliderAnimationController;
  late Animation<int> _backgroundSliderAnimation;

  @override
  void initState() {
    super.initState();

    // Set up animations.
    _backgroundSliderAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _backgroundSliderAnimation =
        IntTween(begin: 0).animate(_backgroundSliderAnimationController);

    // Set up the controller.
    widget.conversationController.messagingController.isRecordingNotifier.addListener(_handleRecordingChange);
    widget.conversationController.messagingController.register(_backgroundSliderAnimationController);
  }

  @override
  void dispose() {
    _backgroundSliderAnimationController.dispose();
    widget.conversationController.messagingController.isRecordingNotifier.removeListener(_handleRecordingChange);
    widget.conversationController.messagingController.dispose();

    super.dispose();
  }

  void _handleRecordingChange() {
    setState(() {
      _backgroundSliderAnimation = IntTween(
        begin: MediaQuery.of(context).size.width.toInt(),
        end: 0,
      ).animate(_backgroundSliderAnimationController);
    });
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: Colors.black26,
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(25),
                child: Stack(
                  children: [
                    ColoredBox(
                      color: Theme.of(context)
                          .extension<MoxxyThemeData>()!
                          .conversationTextFieldColor,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 4,
                          horizontal: 12,
                        ),
                        child: Row(
                          children: [
                            EmojiStickerPickerIcon(
                              keyboardController: widget.keyboardController,
                              tabController: widget.tabController,
                              textFieldFocusNode: widget.textFieldFocusNode,
                            ),
                            Expanded(
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                child: TextField(
                                  controller: widget
                                      .conversationController.textController,
                                  focusNode: widget.textFieldFocusNode,
                                  style: TextStyle(
                                    color: Theme.of(context)
                                        .extension<MoxxyThemeData>()!
                                        .conversationTextFieldTextColor,
                                  ),
                                  decoration: InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                    isDense: true,
                                    hintText: t.pages.conversation.messageHint,
                                    hintStyle: TextStyle(
                                      color: Theme.of(context)
                                          .extension<MoxxyThemeData>()!
                                          .conversationTextFieldHintTextColor,
                                    ),
                                  ),
                                  minLines: 1,
                                  maxLines: 5,
                                ),
                              ),
                            ),
                            StreamBuilder<TextFieldData>(
                              stream: widget
                                  .conversationController.textFieldDataStream,
                              initialData: const TextFieldData(
                                true,
                                null,
                              ),
                              builder: (context, snapshot) {
                                return AnimatedOpacity(
                                  opacity: snapshot.data!.isBodyEmpty &&
                                          snapshot.data!.quotedMessage == null
                                      ? 1
                                      : 0,
                                  duration: const Duration(milliseconds: 200),
                                  child: RecordIcon(widget.conversationController.messagingController),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),

                    // TODO: Maybe a controller that resets the timer is better?
                    // Ensure that the timer gets destroyed and recreated.
                    TextFieldSlider(
                      controller: widget.conversationController.messagingController,
                      animation: _backgroundSliderAnimation,
                    ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 8),
            child: SizedBox(
              width: 45,
              height: 45,
              child: SendButton(
                controller: widget.conversationController.messagingController,
                conversationController: widget.conversationController,
                speedDialValueNotifier: widget.speedDialValueNotifier,
                isEncrypted: widget.isEncrypted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
