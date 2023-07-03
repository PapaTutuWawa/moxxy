import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:moxplatform/moxplatform.dart';
import 'package:moxxyv2/i18n/strings.g.dart';
import 'package:moxxyv2/shared/commands.dart';
import 'package:moxxyv2/shared/models/message.dart';
import 'package:moxxyv2/shared/warning_types.dart';
import 'package:moxxyv2/ui/controller/conversation_controller.dart';
import 'package:moxxyv2/ui/helpers.dart';
import 'package:moxxyv2/ui/widgets/chat/chatbubble.dart';
import 'package:moxxyv2/ui/widgets/context_menu.dart';

/// A data "packet" to describe the selected message.
class SelectedMessageData {
  const SelectedMessageData(
    this.message,
    this.isChatEncrypted,
    this.sentBySelf,
    this.originalPosition,
    this.requiredYOffset,
    this.start,
    this.between,
    this.end,
  );

  /// The message content.
  final Message? message;

  /// Flag indicating whether the current chat is encrypted or not.
  final bool isChatEncrypted;

  /// Flag indicating whether [message] was sent by ourselves or not.
  final bool sentBySelf;

  /// The original screen position of the message.
  final Offset originalPosition;

  /// The offset that is required for the animation to work.
  final double requiredYOffset;

  /// Flags for the message's corners.
  final bool start;
  final bool between;
  final bool end;
}

/// A controller class for managing a [SelectedMessage] widget.
class SelectedMessageController {
  SelectedMessageController(this._controller, this.animation) {
    _controller.addListener(_onAnimationChanged);
  }

  /// Provide the stream to the widget.
  final StreamController<SelectedMessageData> _streamController =
      StreamController<SelectedMessageData>.broadcast();
  Stream<SelectedMessageData> get stream => _streamController.stream;

  /// The [AnimationController] and the animation. Used for detecting the end of the
  /// animation and providing data to the widget.
  final AnimationController _controller;
  final Animation<double> animation;

  /// Flag indicating whether we should reset [state] when the [AnimationController]'s
  /// value hits 0.
  bool _shouldClearMessage = false;

  /// The current state of what the widget is displaying.
  SelectedMessageData state = const SelectedMessageData(
    null,
    false,
    false,
    Offset.zero,
    0,
    false,
    false,
    false,
  );

  void _onAnimationChanged() {
    if (_controller.value == 0 && _shouldClearMessage) {
      // Prevent the widget from constantly being rendered and layouted.
      _streamController.add(
        const SelectedMessageData(
          null,
          false,
          false,
          Offset.zero,
          0,
          false,
          false,
          false,
        ),
      );
      _shouldClearMessage = false;
    } else if (_controller.value == 1) {
      _shouldClearMessage = true;
    }
  }

  /// Mark a message as selected and start the animation.
  void selectMessage(SelectedMessageData data) {
    state = data;
    _streamController.add(data);
    _controller.forward();
  }

  /// Dismiss the message selection
  void dismiss() {
    _controller.reverse();
  }
}

class SelectedMessage extends StatelessWidget {
  const SelectedMessage(this.controller, {super.key});

  /// The controller for managing the state and the animation.
  final SelectedMessageController controller;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SelectedMessageData>(
      initialData: controller.state,
      stream: controller.stream,
      builder: (context, snapshot) {
        if (snapshot.data!.message == null) {
          return const SizedBox();
        }

        return AnimatedBuilder(
          animation: controller.animation,
          builder: (context, child) {
            return Positioned(
              left: snapshot.data!.originalPosition.dx,
              top: snapshot.data!.originalPosition.dy +
                  controller.animation.value * snapshot.data!.requiredYOffset,
              child: IgnorePointer(
                child: child,
              ),
            );
          },
          child: RawChatBubble(
            snapshot.data!.message!,
            MediaQuery.of(context).size.width * 0.6,
            snapshot.data!.sentBySelf,
            snapshot.data!.isChatEncrypted,
            snapshot.data!.start,
            snapshot.data!.between,
            snapshot.data!.end,
          ),
        );
      },
    );
  }
}

class SelectedMessageContextMenu extends StatelessWidget {
  const SelectedMessageContextMenu({
    required this.selectionController,
    required this.conversationController,
    super.key,
  });

  final SelectedMessageController selectionController;

  final BidirectionalConversationController conversationController;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SelectedMessageData>(
      stream: selectionController.stream,
      initialData: selectionController.state,
      builder: (context, snapshot) {
        if (snapshot.data!.message == null) {
          return const SizedBox();
        }

        final sentBySelf = snapshot.data!.sentBySelf;
        final message = snapshot.data!.message!;
        return AnimatedBuilder(
          animation: selectionController.animation,
          builder: (context, _) => Positioned(
            left: sentBySelf ? null : 20,
            right: sentBySelf ? 20 : null,
            bottom: 20,
            child: Opacity(
              opacity: selectionController.animation.value,
              child: ContextMenu(
                children: [
                  if (message.isReactable)
                    ContextMenuItem(
                      icon: Icons.add_reaction,
                      text: t.pages.conversation.addReaction,
                      onPressed: () async {
                        final emoji = await pickEmoji(context, pop: false);
                        if (emoji != null) {
                          await MoxplatformPlugin.handler
                              .getDataSender()
                              .sendData(
                                AddReactionToMessageCommand(
                                  messageId: message.id,
                                  emoji: emoji,
                                  conversationJid:
                                      conversationController.conversationJid,
                                ),
                                awaitable: false,
                              );
                        }

                        selectionController.dismiss();
                      },
                    ),
                  if (message.canRetract(sentBySelf))
                    ContextMenuItem(
                      icon: Icons.delete,
                      text: t.pages.conversation.retract,
                      onPressed: () async {
                        final result = await showConfirmationDialog(
                          t.pages.conversation.retract,
                          t.pages.conversation.retractBody,
                          context,
                        );

                        if (result) {
                          conversationController
                              .retractMessage(message.originId!);
                        }

                        selectionController.dismiss();
                      },
                    ),
                  if (message.canEdit(sentBySelf))
                    ContextMenuItem(
                      icon: Icons.edit,
                      text: t.pages.conversation.edit,
                      onPressed: () {
                        conversationController.beginMessageEditing(
                          message.body,
                          message.quotes,
                          message.id,
                          message.sid,
                        );
                        selectionController.dismiss();
                      },
                    ),
                  if (message.errorMenuVisible)
                    ContextMenuItem(
                      icon: Icons.info_outline,
                      text: t.pages.conversation.showError,
                      onPressed: () {
                        showInfoDialog(
                          t.errors.conversation.messageErrorDialogTitle,
                          message.errorType!.translatableString,
                          context,
                        );
                        selectionController.dismiss();
                      },
                    ),
                  if (message.hasWarning)
                    ContextMenuItem(
                      icon: Icons.warning,
                      text: t.pages.conversation.showWarning,
                      onPressed: () {
                        showInfoDialog(
                          'Warning',
                          warningToTranslatableString(
                            message.warningType!,
                          ),
                          context,
                        );
                        selectionController.dismiss();
                      },
                    ),
                  if (message.isCopyable)
                    ContextMenuItem(
                      icon: Icons.content_copy,
                      text: t.pages.conversation.copy,
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(
                            text: message.body,
                          ),
                        );
                        selectionController.dismiss();

                        // Show an informative toast
                        Fluttertoast.showToast(
                          msg: t.pages.conversation.messageCopied,
                        );
                      },
                    ),
                  if (message.isQuotable && message.conversationJid != '')
                    ContextMenuItem(
                      icon: Icons.forward,
                      text: t.pages.conversation.forward,
                      onPressed: () {
                        showNotImplementedDialog(
                          'sharing',
                          context,
                        );
                        selectionController.dismiss();
                      },
                    ),
                  if (message.isQuotable)
                    ContextMenuItem(
                      icon: Icons.reply,
                      text: t.pages.conversation.quote,
                      onPressed: () {
                        conversationController.quoteMessage(message);
                        selectionController.dismiss();
                      },
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
