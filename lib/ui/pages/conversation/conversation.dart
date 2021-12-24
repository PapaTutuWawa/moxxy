import 'package:flutter/material.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';
import 'package:moxxyv2/ui/widgets/chatbubble.dart';
import "package:moxxyv2/models/message.dart";
import "package:moxxyv2/models/conversation.dart";
import "package:moxxyv2/redux/state.dart";
import "package:moxxyv2/redux/conversation/actions.dart";
import "package:moxxyv2/ui/pages/profile.dart";
import "package:moxxyv2/ui/pages/conversation/arguments.dart";
import "package:moxxyv2/ui/constants.dart";

import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:get_it/get_it.dart';

typedef SendMessageFunction = void Function(String body);

// TODO: Maybe use a PageView to combine ConversationsPage and ConversationPage

class _MessageListViewModel {
  final void Function(bool showSendButton) setShowSendButton;
  final List<Message> messages;
  final Conversation conversation;
  final SendMessageFunction sendMessage;
  final bool showSendButton;
  
  _MessageListViewModel({ required this.conversation, required this.messages, required this.showSendButton, required this.sendMessage, required this.setShowSendButton });
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
    } else {
      // TODO: This
      print("Adding file");
    }
  }

  Widget _renderBubble(List<Message> messages, int index) {
    Message item = messages[index];
    // TODO
    bool start = index - 1 < 0 ? true : messages[index - 1].sent != item.sent;
    bool end = index + 1 >= messages.length ? true : messages[index + 1].sent != item.sent;
    bool between = !start && !end;
    return ChatBubble(
      messageContent: item.body,
      timestamp: item.timestamp,
      sentBySelf: true,
      start: start,
      end: end,
      between: between,
      closerTogether: !end
    );
  }
  
  @override
  Widget build(BuildContext context) {
    var args = ModalRoute.of(context)!.settings.arguments as ConversationPageArguments;
    String jid = args.jid;
    
    return StoreConnector<MoxxyState, _MessageListViewModel>(
      converter: (store) => _MessageListViewModel(
        messages: store.state.messages.containsKey(jid) ? store.state.messages[jid]! : [],
        conversation: store.state.conversations.firstWhere((item) => item.jid == jid),
        showSendButton: store.state.conversationPageState.showSendButton,
        setShowSendButton: (show) => store.dispatch(SetShowSendButtonAction(show: show)),
        sendMessage: (body) => store.dispatch(
          // TODO
          AddMessageAction(
            from: "UwU",
            timestamp: DateTime.now().millisecondsSinceEpoch,
            body: body,
            jid: jid
          )
        )
      ),
      builder: (context, viewModel) {
        return Scaffold(
          appBar: PreferredSize(
            preferredSize: Size.fromHeight(60),
            child: BorderlessTopbar(
              boxShadow: true,
              children: [
                Center(
                  child: InkWell(
                    onTap: () {
                      Navigator.pop(context);
                    },
                    child: Icon(Icons.arrow_back)
                  )
                ),
                Center(
                  child: InkWell(
                    child: Row(
                      children: [
                        Padding(
                          padding: EdgeInsets.only(left: 16.0),
                          child: CircleAvatar(
                            // TODO
                            backgroundImage: NetworkImage(viewModel.conversation.avatarUrl),
                            radius: 25.0
                          )
                        ),
                        Padding(
                          padding: EdgeInsets.only(left: 2.0),
                          child: Text(
                            viewModel.conversation.title,
                            style: TextStyle(
                              fontSize: 20
                            )
                          )
                        )
                      ]
                    ),
                    onTap: () {
                      Navigator.pushNamed(context, "/conversation/profile", arguments: ProfilePageArguments(conversation: viewModel.conversation));
                    }
                  )
                )
              ]
            )
          ),
          body: Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: viewModel.messages.length,
                  itemBuilder: (context, index) => this._renderBubble(viewModel.messages, index)
                )
              ),
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            width: 1,
                            color: BUBBLE_COLOR_SENT
                          )
                        ),
                        // TODO: Fix the TextField being too tall
                        child: TextField(
                          maxLines: 5,
                          minLines: 1,
                          controller: this.controller,
                          onChanged: (value) => this._onMessageTextChanged(value, viewModel),
                          decoration: InputDecoration(
                            hintText: "Send a message...",
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.all(5)
                          )
                        )
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
                            backgroundColor: BUBBLE_COLOR_SENT,
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
                                onTap: () {},
                                backgroundColor: BUBBLE_COLOR_SENT,
                                // TODO: Theme dependent?
                                foregroundColor: Colors.white,
                                label: "Add Image"
                              ),
                              SpeedDialChild(
                                child: Icon(Icons.photo_camera),
                                onTap: () {},
                                backgroundColor: BUBBLE_COLOR_SENT,
                                // TODO: Theme dependent?
                                foregroundColor: Colors.white,
                                label: "Take photo"
                              ),
                              SpeedDialChild(
                                child: Icon(Icons.attach_file),
                                onTap: () {},
                                backgroundColor: BUBBLE_COLOR_SENT,
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
