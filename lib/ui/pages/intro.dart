import 'package:flutter/material.dart';
import 'package:moxxyv2/ui/widgets/topbar.dart';
import "package:moxxyv2/ui/constants.dart";

class IntroPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // TODO: Fix the typography
    return SafeArea(
      child: Scaffold(
        body: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(top: 16.0),
              child: Image.asset(
                "assets/images/logo.png",
                width: 200, height: 200
              )
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                "moxxy",
                style: TextStyle(
                  fontSize: FONTSIZE_TITLE
                )
              )
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: PADDING_VERY_LARGE),
              child: Text(
                "An experiment into building a modern, easy and beautiful XMPP client.",
                style: TextStyle(
                  fontSize: FONTSIZE_BODY
                )
              )
            ),
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: PADDING_VERY_LARGE),
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
              padding: EdgeInsets.symmetric(horizontal: PADDING_VERY_LARGE),
              child: Text(
                "Have no XMPP account? No worries, creating one is really easy.",
                style: TextStyle(
                  fontSize: FONTSIZE_BODY
                )
              )
            ),
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: PADDING_VERY_LARGE).add(EdgeInsets.only(bottom: PADDING_VERY_LARGE)),
                    child: TextButton(
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
