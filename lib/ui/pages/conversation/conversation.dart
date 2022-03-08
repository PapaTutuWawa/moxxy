import "dart:io";

import "package:moxxyv2/ui/widgets/topbar.dart";
import "package:moxxyv2/ui/widgets/chatbubble.dart";
import "package:moxxyv2/ui/widgets/avatar.dart";
import "package:moxxyv2/ui/widgets/textfield.dart";
import "package:moxxyv2/ui/widgets/quotedmessage.dart";
import "package:moxxyv2/ui/pages/profile/profile.dart";
import "package:moxxyv2/ui/pages/conversation/arguments.dart";
import "package:moxxyv2/ui/constants.dart";
import "package:moxxyv2/ui/helpers.dart";
import "package:moxxyv2/shared/models/message.dart";
import "package:moxxyv2/shared/models/conversation.dart";
import "package:moxxyv2/ui/redux/state.dart";
import "package:moxxyv2/ui/redux/conversation/actions.dart";

import "package:flutter/material.dart";
import "package:flutter_speed_dial/flutter_speed_dial.dart";
import "package:flutter_redux/flutter_redux.dart";
import "package:swipeable_tile/swipeable_tile.dart";
import "package:flutter_vibrate/flutter_vibrate.dart";

typedef SendMessageFunction = void Function(String body);

enum ConversationOption {
  close,
  block
}

enum EncryptionOption {
  omemo,
  none
}

PopupMenuItem popupItemWithIcon(dynamic value, String text, IconData icon) {
  return PopupMenuItem(
    value: value,
    child: Row(
      children: [
        Padding(
          padding: const EdgeInsets.only(right: 8.0),
          child: Icon(icon)
        ),
        Text(text)
      ]
    )
  );
}

// TODO: Maybe use a PageView to combine ConversationsPage and ConversationPage
// TODO: Have a list header that appears when the conversation partner is not in the user's
//       roster. It should allow adding the contact to the user's roster or block them.
class _MessageListViewModel {
  final Conversation conversation;
  final List<Message> messages;
  final SendMessageFunction sendMessage;
  final void Function(bool showSendButton) setShowSendButton;
  final bool showSendButton;
  final void Function(bool scrollToEndButton) setShowScrollToEndButton;
  final bool showScrollToEndButton;
  final void Function() closeChat;
  final void Function() resetCurrentConversation;
  final String backgroundPath;
  final Message? quotedMessage;
  final void Function(Message?) setQuotedMessage;
  
  _MessageListViewModel({
      required this.conversation,
      required this.showSendButton,
      required this.sendMessage,
      required this.setShowSendButton,
      required this.showScrollToEndButton,
      required this.setShowScrollToEndButton,
      required this.closeChat,
      required this.messages,
      required this.resetCurrentConversation,
      required this.backgroundPath,
      required this.setQuotedMessage,
      required this.quotedMessage
  });
}

class ConversationPage extends StatefulWidget {
  const ConversationPage({ Key? key }) : super(key: key);

  @override
  _ConversationPageState createState() => _ConversationPageState();
}

class _ConversationPageState extends State<ConversationPage> {
  final TextEditingController controller = TextEditingController();
  final ValueNotifier<bool> _isSpeedDialOpen = ValueNotifier(false);
  
  @override
  void dispose() {
    controller.dispose();

    super.dispose();
  }

  void _onMessageTextChanged(String value, _MessageListViewModel viewModel) {
    // Only dispatch the action if we have to
    bool empty = value == "";
    if (viewModel.showSendButton && empty) {
      viewModel.setShowSendButton(false);
    } else if (!viewModel.showSendButton && !empty) {
      viewModel.setShowSendButton(true);
    }
  }

  void _onSendButtonPressed(_MessageListViewModel viewModel) {
    if (viewModel.showSendButton) {
      viewModel.sendMessage(controller.text);
      controller.clear();
      // NOTE: Calling clear on the controller does not trigger a onChanged on the
      //       TextField
      _onMessageTextChanged("", viewModel);
    }
  }

  Widget _renderBubble(_MessageListViewModel viewModel, int _index, double maxWidth) {
    // TODO: Since we reverse the list: Fix start, end and between
    final index = viewModel.messages.length - 1 - _index;
    Message item = viewModel.messages[index];
    bool start = index - 1 < 0 ? true : viewModel.messages[index - 1].sent != item.sent;
    bool end = index + 1 >= viewModel.messages.length ? true : viewModel.messages[index + 1].sent != item.sent;
    bool between = !start && !end;

    return SwipeableTile.swipeToTrigger(
      direction: SwipeDirection.horizontal,
      swipeThreshold: 0.2,
      onSwiped: (_) => viewModel.setQuotedMessage(item),
      backgroundBuilder: (_, direction, progress) {
        // NOTE: Taken from https://github.com/watery-desert/swipeable_tile/blob/main/example/lib/main.dart#L240
        //       and modified.
        bool vibrated = false;
        return AnimatedBuilder(
          animation: progress,
          builder: (_, __) {
            if (progress.value > 0.9999 && !vibrated) {
              Vibrate.feedback(FeedbackType.light);
              vibrated = true;
            } else if (progress.value < 0.9999) {
              vibrated = false;
            }

            return Container(
              alignment: direction == SwipeDirection.endToStart ? Alignment.centerRight : Alignment.centerLeft,
              child: Padding(
                padding: EdgeInsets.only(
                  right: direction == SwipeDirection.endToStart ? 24.0 : 0.0,
                  left: direction == SwipeDirection.startToEnd ? 24.0 : 0.0
                ),
                child: Transform.scale(
                  scale: Tween<double>(
                    begin: 0.0,
                    end: 1.2,
                  )
                  .animate(
                    CurvedAnimation(
                      parent: progress,
                      curve: const Interval(0.5, 1.0,
                        curve: Curves.linear),
                    ),
                  )
                  .value,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.3),
                      shape: BoxShape.circle
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(
                        Icons.reply,
                        color: Colors.white,
                      )
                    )
                  ),
                ),
              ),
            );
          },
        );
      },
      isEelevated: false,
      key: ValueKey("message;" + item.toString()),
      child: ChatBubble(
        message: item,
        sentBySelf: item.sent,
        start: start,
        end: end,
        between: between,
        closerTogether: !end,
        maxWidth: maxWidth,
      )
    );
  }
  
  @override
  Widget build(BuildContext context) {
    var args = ModalRoute.of(context)!.settings.arguments as ConversationPageArguments;
    String jid = args.jid;
    double maxWidth = MediaQuery.of(context).size.width * 0.6;
    
    return StoreConnector<MoxxyState, _MessageListViewModel>(
      converter: (store) {
        Conversation conversation = store.state.conversations[jid]!;
        return _MessageListViewModel(
          conversation: conversation,
          messages: store.state.messages.containsKey(jid) ? store.state.messages[jid]! : [],
          showSendButton: store.state.conversationPageState.showSendButton,
          setShowSendButton: (show) => store.dispatch(SetShowSendButtonAction(show: show)),
          showScrollToEndButton: store.state.conversationPageState.showScrollToEndButton,
          setShowScrollToEndButton: (show) => store.dispatch(SetShowScrollToEndButtonAction(show: show)),
          closeChat: () => store.dispatch(CloseConversationAction(
              jid: jid,
              id: conversation.id
          )),
          sendMessage: (body) => store.dispatch(
            SendMessageAction(
              timestamp: DateTime.now().millisecondsSinceEpoch,
              body: body,
              jid: jid,
            )
          ),
          resetCurrentConversation: () => store.dispatch(SetOpenConversationAction(jid: null)),
          backgroundPath: store.state.preferencesState.backgroundPath,
          setQuotedMessage: (msg) => store.dispatch(QuoteMessageUIAction(msg)),
          quotedMessage: store.state.conversationPageState.quotedMessage
        );
      },
      builder: (context, viewModel) {
        return WillPopScope(
          onWillPop: () async {
            viewModel.resetCurrentConversation();
            return true;
          },
          child: Scaffold(
            appBar: BorderlessTopbar.avatarAndName(
              avatar: AvatarWrapper(
                radius: 25.0,
                avatarUrl: viewModel.conversation.avatarUrl,
                alt: Text(viewModel.conversation.title[0])
              ),
              title: viewModel.conversation.title,
              onTapFunction: () => Navigator.pushNamed(context, profileRoute, arguments: ProfilePageArguments(conversation: viewModel.conversation, isSelfProfile: false)),
              showBackButton: true,
              extra: [
                PopupMenuButton(
                  onSelected: (result) {
                    if (result == EncryptionOption.omemo) {
                      showNotImplementedDialog("End-to-End encryption", context);
                    }
                  },
                  icon: const Icon(Icons.lock_open),
                  itemBuilder: (BuildContext c) => [
                    popupItemWithIcon(EncryptionOption.none, "Unencrypted", Icons.lock_open),
                    popupItemWithIcon(EncryptionOption.omemo, "Encrypted", Icons.lock),
                  ]
                ),
                PopupMenuButton(
                  onSelected: (result) {
                    switch (result) {
                      case ConversationOption.close: {
                        showConfirmationDialog(
                          "Close Chat",
                          "Are you sure you want to close this chat?",
                          context,
                          () {
                            viewModel.closeChat();
                            Navigator.of(context).pop();
                          }
                        );
                      }
                      break;
                      case ConversationOption.block: {
                        showNotImplementedDialog("blocking", context);
                      }
                      break;
                    }
                  },
                  icon: const Icon(Icons.more_vert),
                  itemBuilder: (BuildContext c) => [
                    popupItemWithIcon(ConversationOption.close, "Close chat", Icons.close),
                    popupItemWithIcon(ConversationOption.block, "Block contact", Icons.block)
                  ]
                )
              ]
            ),
            body: Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        decoration: viewModel.backgroundPath.isNotEmpty ? BoxDecoration(
                          image: DecorationImage(
                            fit: BoxFit.cover,
                            image: FileImage(File(viewModel.backgroundPath))
                          )
                        ) : null,
                        child: ListView.builder(
                          reverse: true,
                          itemCount: viewModel.messages.length,
                          itemBuilder: (context, index) => _renderBubble(viewModel, index, maxWidth)
                        )
                      ),
                      Positioned(
                        bottom: 64.0,
                        right: 16.0,
                        child: Visibility(
                          // TODO: Show if we're not scrolled to the end
                          visible: viewModel.showScrollToEndButton,
                          child: SizedBox(
                            height: 30.0,
                            width: 30.0,
                            child: FloatingActionButton(
                              child: const Icon(Icons.arrow_downward, color: Colors.white),
                              // TODO
                              onPressed: () {}
                            )
                          )
                        )
                      )
                    ]
                  )
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: CustomTextField(
                          maxLines: 5,
                          minLines: 1,
                          hintText: "Send a message...",
                          isDense: true,
                          controller: controller,
                          onChanged: (value) => _onMessageTextChanged(value, viewModel),
                          contentPadding: textfieldPaddingConversation,
                          cornerRadius: textfieldRadiusConversation,
                          // TODO: Handle media messages being quoted
                          topWidget: viewModel.quotedMessage != null ? QuotedMessageWidget(
                            message: viewModel.quotedMessage!,
                            resetQuotedMessage: () => viewModel.setQuotedMessage(null)
                          ) : null
                        )
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0),
                        // NOTE: https://stackoverflow.com/a/52786741
                        //       Thank you kind sir
                        child: SizedBox(
                          height: 45.0,
                          width: 45.0,
                          child: FittedBox(
                            child: SpeedDial(
                              icon: viewModel.showSendButton ? Icons.send : Icons.add,
                              visible: true,
                              curve: Curves.bounceInOut,
                              backgroundColor: primaryColor,
                              // TODO: Theme dependent?
                              foregroundColor: Colors.white,
                              openCloseDial: _isSpeedDialOpen,
                              onPress: () {
                                if (viewModel.showSendButton) {
                                  _onSendButtonPressed(viewModel);
                                } else {
                                  _isSpeedDialOpen.value = true;
                                }
                              },
                              children: [
                                SpeedDialChild(
                                  child: const Icon(Icons.image),
                                  onTap: () {
                                    showNotImplementedDialog("sending files", context);
                                    //Navigator.pushNamed(context, sendFilesRoute);
                                  },
                                  backgroundColor: primaryColor,
                                  // TODO: Theme dependent?
                                  foregroundColor: Colors.white,
                                  label: "Send Image"
                                ),
                                SpeedDialChild(
                                  child: const Icon(Icons.photo_camera),
                                  onTap: () {
                                    showNotImplementedDialog("sending files", context);
                                  },
                                  backgroundColor: primaryColor,
                                  // TODO: Theme dependent?
                                  foregroundColor: Colors.white,
                                  label: "Take photo"
                                ),
                                SpeedDialChild(
                                  child: const Icon(Icons.attach_file),
                                  onTap: () {
                                    showNotImplementedDialog("sending files", context);
                                  },
                                  backgroundColor: primaryColor,
                                  // TODO: Theme dependent?
                                  foregroundColor: Colors.white,
                                  label: "Add file"
                                ),
                              ]
                            )
                          )
                        )
                      ) 
                    ]
                  )
                )
              ]
            )
          )
        );
      }
    );
  }
}
