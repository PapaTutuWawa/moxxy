import 'package:flutter/material.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';
import 'package:moxxyv2/ui/widgets/chatbubble.dart';

class _ConversationPageState extends State<ConversationPage> {
  bool _showSendButton = false;
  TextEditingController controller = TextEditingController();

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

  void _onSendButtonPressed() {
    if (this._showSendButton) {
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
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: BorderlessTopbar(
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
                        backgroundImage: NetworkImage("https://external-content.duckduckgo.com/iu/?u=https%3A%2F%2Ftse3.mm.bing.net%2Fth%3Fid%3DOIP.MkXhyVPrn9eQGC1CTOyTYAHaHa%26pid%3DApi&f=1"),
                        radius: 25.0
                      )
                    ),
                    Padding(
                      padding: EdgeInsets.only(left: 2.0),
                      child: Text(
                        "Ojou",
                        style: TextStyle(
                          fontSize: 20
                        )
                      )
                    )
                  ]
                ),
                onTap: () {
                  Navigator.pushNamed(context, "/conversation/profile");
                }
              )
            ),
            Spacer(),
            Center(
              child: InkWell(
                // TODO: Implement
                onTap: () {},
                // TODO: Find a better icon
                child: Icon(Icons.menu)
              )
            )
          ]
        )
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              children: [
                ChatBubble(
                  messageContent: "Hello",
                  sentBySelf: true
                ),
                ChatBubble(
                  messageContent: "Hello right back",
                  sentBySelf: false
                ),
                ChatBubble(
                  messageContent: "What a nice person you are!",
                  sentBySelf: true
                )
              ]
            )
          ),
          Padding(
            padding: EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        width: 1,
                        color: Colors.purple
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
                      child: FloatingActionButton(
                        child: Icon(
                          this._showSendButton ? Icons.send : Icons.add
                        ),
                        onPressed: this._onSendButtonPressed
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
}

class ConversationPage extends StatefulWidget {
  const ConversationPage({ Key? key }) : super(key: key);

  @override
  _ConversationPageState createState() => _ConversationPageState();
  
}
