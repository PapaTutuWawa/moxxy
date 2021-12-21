import 'package:flutter/material.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';

class AddContactPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: BorderlessTopbar(
          children: [
            BackButton(),
            Text(
              "Add new contact",
              style: TextStyle(
                fontSize: 19
              )
            )
          ]
        )
      ),
      // TODO: The TextFields look a bit too smal
      // TODO: Hide the LinearProgressIndicator if we're not doing anything
      // TODO: Disable the inputs and the BackButton if we're working on loggin in
      body: Column(
        children: [
          LinearProgressIndicator(value: null),

          Padding(
            padding: EdgeInsets.only(top: 8.0, left: 16.0, right: 16.0),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  width: 1,
                  color: Colors.purple
                )
              ),
              child: TextField(
                maxLines: 1,
                decoration: InputDecoration(
                  labelText: "XMPP-Address",
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.only(top: 4.0, bottom: 4.0, left: 8.0, right: 8.0),
                  suffixIcon: Padding(
                    padding: EdgeInsetsDirectional.only(end: 6.0),
                    child: Icon(Icons.qr_code)
                  )
                )
              )
            )
          ),

          Padding(
            padding: EdgeInsets.all(16.0),
            child: Text("You can add a contact either by typing in their XMPP address or by scanning their QR code")
          ),
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    child: Text("Add to contacts"),
                    // TODO: Add to roster and open a chat
                    onPressed: () {}
                  )
                )
              )
            ]
          )
        ]
      )
    );
  }
}
