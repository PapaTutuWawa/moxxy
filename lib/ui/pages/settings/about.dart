import "dart:collection";
import 'package:flutter/material.dart';
import "package:moxxyv2/ui/constants.dart";
import "package:moxxyv2/ui/widgets/topbar.dart";

import "package:url_launcher/url_launcher.dart";

// TODO: Include license text?
// TODO: Maybe include the version number
class SettingsAboutPage extends StatelessWidget {
  void _openUrl(String url) async {
    if (!await launch(url)) {
      // TODO: Show a popup to copy the url
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(60),
        child: BorderlessTopbar(
          children: [
            BackButton()
          ]
        )
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: PADDING_VERY_LARGE),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Image.asset(
              "assets/images/logo.png",
              width: 200, height: 200
            ),
            Text(
              "moxxy",
              style: TextStyle(
                fontSize: 40
              )
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                "An experimental XMPP client that is beautiful, modern and easy to use",
                style: TextStyle(
                  fontSize: 15
                )
              )
            ),
            Text("Licensed under GPL3"),
            Padding(
              padding: EdgeInsets.symmetric(vertical: 8.0),
              child: ElevatedButton(
                child: Text("View source code"),
                onPressed: () => this._openUrl("https://github.com/Polynomdivision/moxxyv2")
              )
            ) 
          ]
        )
      )
    );
  }
}
