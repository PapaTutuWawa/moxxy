import 'package:flutter/material.dart';

class ChatBubble extends StatelessWidget {
  String messageContent;
  bool sentBySelf;

  ChatBubble({ required this.messageContent, required this.sentBySelf });

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: EdgeInsets.only(
          left: 8.0,
          right: 8.0,
          top: 5.0
        ),
        child: Row(
          mainAxisAlignment: this.sentBySelf ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: this.sentBySelf ? Color.fromRGBO(162, 68, 173, 1.0) : Color.fromRGBO(44, 62, 80, 1.0),
                // TODO: Smaller radius if messages belong together
                borderRadius: BorderRadius.circular(10)
              ),
              child: Padding(
                padding: EdgeInsets.all(8.0),
                // TODO: Fix overflow
                child: IntrinsicWidth(child: Column(
                    children: [
                      Text(
                        this.messageContent,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 17
                        )
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          // TODO: Timestamp
                          Padding(
                            padding: EdgeInsets.only(top: 3.0),
                            child: Text(
                              "12:00",
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey
                              )
                            )
                          ) 
                        ]
                      )
                    ]
                  )
                )
              )
            )
          ]
        )
      );
  }
}
