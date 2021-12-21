import 'package:flutter/material.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';

class IntroPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: Fix the typography
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: EdgeInsetsDirectional.only(top: 32.0),
            child: Text("moxxy")
          ),
          Padding(
            padding: EdgeInsets.all(16.0),
            child: Text(
              "An experiment into building a modern easy-to-use XMPP client",
              style: TextStyle(
                fontSize: 20
              )
            )
          ),
          ElevatedButton(
            child: Text("Login"),
            onPressed: () => Navigator.pushNamed(context, "/login")
          ),
          ElevatedButton(
            child: Text("Register"),
            onPressed: () => Navigator.pushNamed(context, "/register")
          )
        ]
      )
    );
  }
}
