import "dart:async";
import "package:flutter/material.dart";

import "package:moxxyv2/ui/widgets/topbar.dart";
import "package:moxxyv2/ui/widgets/chatbubble.dart";
import "package:moxxyv2/ui/widgets/avatar.dart";
import "package:moxxyv2/ui/widgets/textfield.dart";
import "package:moxxyv2/models/message.dart";
import "package:moxxyv2/models/conversation.dart";
import "package:moxxyv2/redux/state.dart";
import "package:moxxyv2/redux/conversation/actions.dart";
import "package:moxxyv2/ui/pages/profile/profile.dart";
import "package:moxxyv2/ui/pages/conversation/arguments.dart";
import "package:moxxyv2/ui/constants.dart";
import "package:moxxyv2/ui/helpers.dart";

import "package:flutter_speed_dial/flutter_speed_dial.dart";
import "package:flutter_redux/flutter_redux.dart";
import "package:redux/redux.dart";
import "package:get_it/get_it.dart";

typedef SendMessageFunction = void Function(String body);

enum ConversationOption {
  CLOSE,
  BLOCK
}

PopupMenuItem popupItemWithIcon(dynamic value, String text, IconData icon) {
  return PopupMenuItem(
    value: value,
    child: Row(
      children: [
        Padding(
          padding: EdgeInsets.only(right: 8.0),
          child: Icon(icon)
        ),
        Text(text)
      ]
    )
  );
}

// TODO: Maybe use a PageView to combine ConversationsPage and ConversationPage

class _MessageListViewModel {
  final Conversation conversation;
  final List<Message> messages;
  final SendMessageFunction sendMessage;
  final void Function(bool showSendButton) setShowSendButton;
  final bool showSendButton;
  final void Function(bool scrollToEndButton) setShowScrollToEndButton;
  final bool showScrollToEndButton;
  final void Function() closeChat;
 
  _MessageListViewModel({ required this.conversation, required this.showSendButton, required this.sendMessage, required this.setShowSendButton, required this.showScrollToEndButton, required this.setShowScrollToEndButton, required this.closeChat, required this.messages });
}

class ConversationPage extends StatelessWidget {
  TextEditingController controller = TextEditingController();
  ValueNotifier<bool> _isSpeedDialOpen = ValueNotifier(false);

  // TODO
  /*
  @override
  void dispose() {
    this.controller.dispose();
    super.dispose();
  }
  */

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
      viewModel.sendMessage(this.controller.text);

      // TODO: Actual sending
      this.controller.clear();
      // NOTE: Calling clear on the controller does not trigger a onChanged on the
      //       TextField
      this._onMessageTextChanged("", viewModel);
    }
  }

  Widget _renderBubble(List<Message> messages, int index, double maxWidth) {
    Message item = messages[index];
    bool start = index - 1 < 0 ? true : messages[index - 1].sent != item.sent;
    bool end = index + 1 >= messages.length ? true : messages[index + 1].sent != item.sent;
    bool between = !start && !end;

    return ChatBubble(
      message: item,
      sentBySelf: item.sent,
      start: start,
      end: end,
      between: between,
      closerTogether: !end,
      maxWidth: maxWidth,
      // TODO: Maybe just use a ValueKey
      key: UniqueKey()
    );
  }
  
  @override
  Widget build(BuildContext context) {
    var args = ModalRoute.of(context)!.settings.arguments as ConversationPageArguments;
    String jid = args.jid;
    double maxWidth = MediaQuery.of(context).size.width * 0.6;
    
    return StoreConnector<MoxxyState, _MessageListViewModel>(
      converter: (store) {
        Conversation conversation = store.state.conversations.firstWhere((item) => item.jid == jid);
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
            // TODO
            SendMessageAction(
              from: "UwU",
              timestamp: DateTime.now().millisecondsSinceEpoch,
              body: body,
              jid: jid,
              cid: conversation.id
            )
          )
        );
      },
      builder: (context, viewModel) {
        return Scaffold(
          appBar: BorderlessTopbar.avatarAndName(
            avatar: AvatarWrapper(
              radius: 25.0,
              avatarUrl: viewModel.conversation.avatarUrl,
              alt: Text(viewModel.conversation.title[0])
            ),
            title: viewModel.conversation.title,
            onTapFunction: () => Navigator.pushNamed(context, "/conversation/profile", arguments: ProfilePageArguments(conversation: viewModel.conversation, isSelfProfile: false)),
            showBackButton: true,
            extra: [
              PopupMenuButton(
                onSelected: (result) {
                  if (result == "omemo") {
                    showNotImplementedDialog("End-to-End encryption", context);
                  }
                },
                icon: Icon(Icons.lock_open),
                itemBuilder: (BuildContext c) => [
                  popupItemWithIcon("unencrypted", "Unencrypted", Icons.lock_open),
                  popupItemWithIcon("omemo", "Encrypted", Icons.lock),
                ]
              ),
              PopupMenuButton(
                onSelected: (result) {
                  switch (result) {
                    case ConversationOption.CLOSE: {
                      // TODO: Ask for confirmation
                      // TODO: Fix crash because we're still here and our conversation is gone
                      // => Maybe give the entire conversation as an argument?
                      viewModel.closeChat();
                    }
                    break;
                    default: {
                      showNotImplementedDialog("chat-closing", context);
                    }
                    break;
                  }
                },
                icon: Icon(Icons.more_vert),
                itemBuilder: (BuildContext c) => [
                  popupItemWithIcon(ConversationOption.CLOSE, "Close chat", Icons.close),
                  popupItemWithIcon(ConversationOption.BLOCK, "Block contact", Icons.block)
                ]
              )
            ]
          ),
          body: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    ListView.builder(
                      itemCount: viewModel.messages.length,
                      itemBuilder: (context, index) => this._renderBubble(viewModel.messages, index, maxWidth)
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
                            child: Icon(Icons.arrow_downward, color: Colors.white),
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
                padding: EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: CustomTextField(
                        maxLines: 5,
                        minLines: 1,
                        hintText: "Send a message...",
                        isDense: true,
                        controller: this.controller,
                        onChanged: (value) => this._onMessageTextChanged(value, viewModel),
                        contentPadding: TEXTFIELD_PADDING_CONVERSATION,
                        cornerRadius: TEXTFIELD_RADIUS_CONVERSATION,
                      )
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 8.0),
                      // NOTE: https://stackoverflow.com/a/52786741
                      //       Thank you kind sir
                      child: Container(
                        height: 45.0,
                        width: 45.0,
                        child: FittedBox(
                          child: SpeedDial(
                            icon: viewModel.showSendButton ? Icons.send : Icons.add,
                            visible: true,
                            curve: Curves.bounceInOut,
                            backgroundColor: PRIMARY_COLOR,
                            // TODO: Theme dependent?
                            foregroundColor: Colors.white,
                            openCloseDial: this._isSpeedDialOpen,
                            onPress: () {
                              if (viewModel.showSendButton) {
                                this._onSendButtonPressed(viewModel);
                              } else {
                                this._isSpeedDialOpen.value = true;
                              }
                            },
                            children: [
                              SpeedDialChild(
                                child: Icon(Icons.image),
                                onTap: () {
                                  //showNotImplementedDialog("sending files", context);
                                  Navigator.pushNamed(context, "/conversation/send_files");
                                },
                                backgroundColor: PRIMARY_COLOR,
                                // TODO: Theme dependent?
                                foregroundColor: Colors.white,
                                label: "Send Image"
                              ),
                              SpeedDialChild(
                                child: Icon(Icons.photo_camera),
                                onTap: () {
                                  showNotImplementedDialog("sending files", context);
                                },
                                backgroundColor: PRIMARY_COLOR,
                                // TODO: Theme dependent?
                                foregroundColor: Colors.white,
                                label: "Take photo"
                              ),
                              SpeedDialChild(
                                child: Icon(Icons.attach_file),
                                onTap: () {
                                  showNotImplementedDialog("sending files", context);
                                },
                                backgroundColor: PRIMARY_COLOR,
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
        );
      }
    );
  }
}
