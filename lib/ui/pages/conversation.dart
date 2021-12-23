import 'package:flutter/material.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';
import 'package:moxxyv2/ui/widgets/chatbubble.dart';
import "package:moxxyv2/models/message.dart";
import "package:moxxyv2/models/conversation.dart";
import "package:moxxyv2/redux/state.dart";
import "package:moxxyv2/redux/conversation/actions.dart";
import "package:moxxyv2/repositories/conversations.dart";
import "package:moxxyv2/ui/pages/profile.dart";
import "package:moxxyv2/ui/constants.dart";

import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:flutter_redux/flutter_redux.dart';
import 'package:redux/redux.dart';
import 'package:get_it/get_it.dart';

typedef SendMessageFunction = void Function(String body);

// TODO: Maybe use a PageView to combine ConversationsPage and ConversationPage

// TODO: Move to a separate file
class ConversationPageArguments {
  final String jid;

  ConversationPageArguments({ required this.jid });
}

class _MessageListViewModel {
  final List<Message> messages;
  final SendMessageFunction sendMessage;
  
  _MessageListViewModel({ required this.messages, required this.sendMessage });
}

class _ConversationPageState extends State<ConversationPage> {
  bool _showSendButton = false;
  TextEditingController controller = TextEditingController();
  ValueNotifier<bool> _isSpeedDialOpen = ValueNotifier(false);

  _ConversationPageState();
  
  @override
  void dispose() {
    this.controller.dispose();
    super.dispose();
  }


  void _onMessageTextChanged(String value) {
    setState(() {
        this._showSendButton = value != "";
    });
  }

  void _onSendButtonPressed(_MessageListViewModel model) {
    if (this._showSendButton) {
      model.sendMessage(this.controller.text);

      // TODO: Actual sending
      this.controller.clear();
      // NOTE: Calling clear on the controller does not trigger a onChanged on the
      //       TextField
      this._onMessageTextChanged("");
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

    Conversation conversation = GetIt.I.get<ConversationRepository>().getConversation(args.jid)!;
    String jid = conversation.jid;
    
    return StoreConnector<MoxxyState, _MessageListViewModel>(
      converter: (store) => _MessageListViewModel(
        // TODO
        messages: store.state.messages.containsKey(jid) ? store.state.messages[jid]! : [],
        sendMessage: (body) => store.dispatch(
          // TODO
          AddMessageAction(
            from: "UwU",
            timestamp: "12:00",
            body: body,
            jid: jid
          )
        )
      ),
      builder: (context, viewModel) => Scaffold(
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
                          backgroundImage: NetworkImage(conversation.avatarUrl),
                          radius: 25.0
                        )
                      ),
                      Padding(
                        padding: EdgeInsets.only(left: 2.0),
                        child: Text(
                          conversation.title,
                          style: TextStyle(
                            fontSize: 20
                          )
                        )
                      )
                    ]
                  ),
                  onTap: () {
                    Navigator.pushNamed(context, "/conversation/profile", arguments: ProfilePageArguments(conversation: conversation));
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
                        onChanged: this._onMessageTextChanged,
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
                          icon: this._showSendButton ? Icons.send : Icons.add,
                          visible: true,
                          curve: Curves.bounceInOut,
                          backgroundColor: BUBBLE_COLOR_SENT,
                          // TODO: Theme dependent?
                          foregroundColor: Colors.white,
                          openCloseDial: this._isSpeedDialOpen,
                          onPress: () {
                            if (this._showSendButton) {
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
      ) 
    );
  }
}

class ConversationPage extends StatefulWidget {
  const ConversationPage({ Key? key }) : super(key: key);

  @override
  _ConversationPageState createState() => _ConversationPageState();
  
}
