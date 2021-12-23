import 'package:flutter/material.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';

class IntroPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: Fix the typography
    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            Padding(
              padding: EdgeInsetsDirectional.only(top: 32.0),
              child: Text(
                "moxxy",
                style: TextStyle(
                  fontSize: 40
                )
              )
            ),
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Image.asset(
                "assets/images/logo.png",
                width: 200, height: 200
              )
            ),
            Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                "An experiment into building a modern easy-to-use XMPP client",
                style: TextStyle(
                  fontSize: 15
                )
              )
            ),
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.all(8.0),
                    child: ElevatedButton(
                      child: Text("Login"),
                      onPressed: () => Navigator.pushNamed(context, "/login")
                    )
                  )
                )
              ]
            ),
            Spacer(),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                "Have no XMPP account? No worries, creating one is really easy.",
                style: TextStyle(
                  fontSize: 15
                )
              )
            ),
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: 8.0, right: 8.0, bottom: 8.0, top: 2.0),
                    child: ElevatedButton(
                      child: Text("Register"),
                      onPressed: () => Navigator.pushNamed(context, "/register")
                    )
                  )
                )
              ]
            )
          ]
        )
      )
    );
  }
}
