import 'package:flutter/material.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';

class RegistrationPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: BorderlessTopbar(
          children: [
            BackButton(),
            Text(
              "Register",
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
            padding: EdgeInsets.all(16.0),
            child: Text("XMPP is a lot like e-mail: You can send e-mails to people who are not using your specific e-mail provider. As such, there are a lot of XMPP providers. To help you, we chose a random one from a curated list. You only have to pick a username.")
          ),
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
                  labelText: "Username",
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.only(top: 4.0, bottom: 4.0, left: 8.0, right: 8.0),
                  suffixText: "@polynom.me",
                  suffixIcon: Padding(
                    padding: EdgeInsetsDirectional.only(end: 6.0),
                    child: Icon(Icons.refresh)
                  )
                )
              )
            )
          ),
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: EdgeInsets.all(16.0),
                  child: ElevatedButton(
                    child: Text("Register"),
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
